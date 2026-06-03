# export-clues-single-csv-offline.ps1
# 离线友好：只依赖 PowerShell + 后端 API，不依赖 Excel 组件或额外模块

$ErrorActionPreference = "Stop"

# ================= 固定参数区（按需改） =================
$ApiBase = "http://12.33.113.78:5173/api/v1"  # 离线环境
# $ApiBase = "http://127.0.0.1:8081/api/v1"      # 开发环境(临时验证)

# 日期范围（硬要求）
$DataDateFrom = "2026-05-01"
$DataDateTo   = "2026-05-22"

# 其他筛选（可空）
$Filter = @{
  keyword    = ""
  status     = ""
  mark_tag   = ""
  distribute = ""
  region     = ""
  score_min  = ""
  score_max  = ""
  # 导出场景建议稳定排序，降低分页重复/漏数风险
  sort_by    = "id"
  sort_order = "asc"
}

$PageSize = 200
$TimeoutSec = 60

$OutDir = Join-Path $PSScriptRoot "exports"
if (-not (Test-Path $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$OutCsv = Join-Path $OutDir "线索导出_${DataDateFrom}_to_${DataDateTo}.csv"
# ======================================================

function Build-QueryString([hashtable]$kv) {
  $parts = @()
  foreach ($k in $kv.Keys) {
    $v = [string]$kv[$k]
    if ($null -ne $v -and $v -ne "") {
      $parts += ("{0}={1}" -f [uri]::EscapeDataString($k), [uri]::EscapeDataString($v))
    }
  }
  return ($parts -join "&")
}

function Invoke-ApiGet([string]$url) {
  $resp = Invoke-RestMethod -Method GET -Uri $url -TimeoutSec $TimeoutSec
  if (-not $resp -or $resp.code -ne "0") {
    throw "接口返回异常: $($resp | ConvertTo-Json -Depth 8)"
  }
  return $resp.data
}

function SafeText($v) {
  if ($null -eq $v) { return "" }
  return [string]$v
}

function Build-DetailText($d) {
  if ($null -eq $d) { return "" }

  $lines = @(
    "type: $(SafeText $d.type)"
    "level: $(SafeText $d.level)"
    "msisdn_1: $(SafeText $d.msisdn_1)"
    "msisdn_2: $(SafeText $d.msisdn_2)"
    "cnt: $(SafeText $d.cnt)"
    "cnt_dt: $(SafeText $d.cnt_dt)"
    "message: $(SafeText $d.message)"
    "summary: $(SafeText $d.summary)"
    "region: $(SafeText $d.region)"
    "info: $(SafeText $d.info)"
    "assign_to: $(SafeText $d.assign_to)"
    "score: $(SafeText $d.score)"
    "qklx: $(SafeText $d.qklx)"
    "label2: $(SafeText $d.label2)"
    "user_id: $(SafeText $d.user_id)"
    "user_name: $(SafeText $d.user_name)"
    "status: $(SafeText $d.status)"
    "feedback: $(SafeText $d.feedback)"
    "feedback_time: $(SafeText $d.feedback_time)"
    "feedback_username: $(SafeText $d.feedback_username)"
    "remark: $(SafeText $d.remark)"
    "mark_tag: $(SafeText $d.mark_tag)"
    "distribute: $(SafeText $d.distribute)"
    "update_time: $(SafeText $d.update_time)"
    "data_date: $(SafeText $d.data_date)"
  )
  return ($lines -join "`n")
}

function Build-FeedbackText($arr) {
  if ($null -eq $arr -or @($arr).Count -eq 0) { return "" }
  $chunks = @()
  $i = 0
  foreach ($f in @($arr)) {
    $i++
    $chunks += @(
      "[$i] time=$(SafeText $f.feedback_time)"
      "    user=$(SafeText $f.feedback_username)"
      "    content=$(SafeText $f.feedback)"
    ) -join "`n"
  }
  return ($chunks -join "`n----------------`n")
}

function Build-MessagesText($arr) {
  if ($null -eq $arr -or @($arr).Count -eq 0) { return "" }
  $chunks = @()
  $i = 0
  foreach ($m in @($arr)) {
    $i++
    $chunks += @(
      "[$i] time=$(SafeText $m.capture_time)"
      "    sender=$(SafeText $m.sender)"
      "    message=$(SafeText $m.message)"
    ) -join "`n"
  }
  return ($chunks -join "`n----------------`n")
}

Write-Host "[INFO] 开始导出..."
Write-Host "[INFO] 日期范围: $DataDateFrom ~ $DataDateTo"

# 1) 拉取线索池（分页）
$listById = @{}
$page = 1
$total = 0

while ($true) {
  $query = @{
    page           = [string]$page
    page_size      = [string]$PageSize
    data_date_from = $DataDateFrom
    data_date_to   = $DataDateTo
  }
  foreach ($k in $Filter.Keys) { $query[$k] = $Filter[$k] }

  $beforeCount = $listById.Count
  $url = "$ApiBase/clues?$(Build-QueryString $query)"
  $data = Invoke-ApiGet -url $url
  $pageList = @($data.list)

  if ($page -eq 1) {
    $total = [int]$data.total
    Write-Host "[INFO] 命中总数: $total"
  }

  foreach ($item in $pageList) {
    if ($item.id) { $listById["$($item.id)"] = $item }
  }

  Write-Host "[INFO] 第 $page 页完成，累计 $($listById.Count)/$total"

  if ($listById.Count -ge $total) { break }

  if ($pageList.Count -eq 0) {
    Write-Host "[WARN] 第 $page 页返回空列表，提前结束分页。"
    break
  }

  if ($listById.Count -eq $beforeCount) {
    Write-Host "[WARN] 第 $page 页未新增任何线索ID，可能出现分页重复。已提前终止分页以避免死循环。"
    break
  }

  $page++
}

if ($listById.Count -eq 0) {
  Write-Host "[WARN] 无数据，结束。"
  exit 0
}

# 2) 拉详情/反馈/短信并合并
$ids = @($listById.Keys)
$rows = New-Object System.Collections.Generic.List[object]

$idx = 0
foreach ($id in $ids) {
  $idx++

  $detail = $null
  $feedbacks = @()
  $messages = @()

  try {
    $detail = Invoke-ApiGet "$ApiBase/clues/$([uri]::EscapeDataString($id))/detail"
  } catch {
    Write-Host "[WARN] detail 请求失败: id=$id, err=$($_.Exception.Message)"
  }

  try {
    $feedbacks = Invoke-ApiGet "$ApiBase/clues/$([uri]::EscapeDataString($id))/feedbacks"
  } catch {
    Write-Host "[WARN] feedbacks 请求失败: id=$id, err=$($_.Exception.Message)"
  }

  try {
    $messages = Invoke-ApiGet "$ApiBase/clues/$([uri]::EscapeDataString($id))/messages"
  } catch {
    Write-Host "[WARN] messages 请求失败: id=$id, err=$($_.Exception.Message)"
  }

  $listItem = $listById[$id]

  $rows.Add([PSCustomObject]@{
    # 主键
    线索ID = $id

    # 线索池常见字段
    类型               = SafeText $listItem.type
    线索等级           = SafeText $listItem.level
    号码1              = SafeText $listItem.msisdn_1
    号码2              = SafeText $listItem.msisdn_2
    分数               = SafeText $listItem.score
    状态               = SafeText $listItem.status
    分配               = SafeText $listItem.distribute
    分配负责人         = SafeText $listItem.assign_to
    标记               = SafeText $listItem.mark_tag
    前科类型           = SafeText $listItem.qklx
    属地               = SafeText $listItem.region
    短信全文           = SafeText $listItem.message
    AI总结             = SafeText $listItem.summary
    备注               = SafeText $listItem.remark
    额外信息           = SafeText $listItem.info
    数据日期           = SafeText $listItem.data_date
    更新时间           = SafeText $listItem.update_time
    最新反馈           = SafeText $listItem.feedback
    最新反馈时间       = SafeText $listItem.feedback_time
    最新反馈人         = SafeText $listItem.feedback_username

    # 压缩字段（单元格多行）
    详情压缩           = Build-DetailText $detail
    历史反馈压缩       = Build-FeedbackText $feedbacks
    上下文短信压缩     = Build-MessagesText $messages
  })

  if (($idx % 20) -eq 0 -or $idx -eq $ids.Count) {
    Write-Host "[INFO] 合并进度: $idx/$($ids.Count)"
  }
}

# 3) 导出 CSV（UTF8）
$rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "[DONE] 导出完成：$OutCsv"
Write-Host "[DONE] 总行数：$($rows.Count)"
