# 手机号线索匹配与导出工具（多线程版）

## 功能

1. 读取 `msisdn_score.xlsx` 中 **A 列**的手机号（跳过表头），在 `nb_tab_grjd_summary` 表中通过 `msisdn_1` / `msisdn_2` 精确匹配
2. 将匹配到的**线索数量**写入 **E 列**，匹配到的**线索ID**（逗号分隔）写入 **F 列**，输出 `msisdn_score_matched.xlsx`
3. 将所有匹配线索的**完整数据**导出到 `id-export.xlsx`（字段与系统批量导出功能一致，共 24 列）
4. B、C、D 列原始数据完整保留

## 前置条件

- Go 1.21+ 环境
- 可访问目标 MySQL（`sdata` 库，含 `nb_tab_grjd_summary`、`nb_tab_grjd_message`；`wxzdb` 库，含 `nb_tab_grjd_workflow_state`、`grjd_distribute`、`nb_tab_grjd_feedback_history`）
- `config/prism-config.json` 已配置 `mysql.dsn`（指向 sdata 库）

## 输入文件格式

`msisdn_score.xlsx`（第一个 Sheet）：

| A列 | B列 | C列 | D列 | E列（自动生成） | F列（自动生成） |
|-----|-----|-----|-----|----------------|----------------|
| 手机号 | *(原有数据)* | *(原有数据)* | *(原有数据)* | 匹配数 | 匹配线索ID列表 |
| 13812345678 | X | Y | Z | 3 | id1,id2,id3 |

- A 列必填，B/C/D 列有数据则保留
- **表头行会被跳过**

## 查询逻辑

对每个手机号执行：

```sql
SELECT id FROM nb_tab_grjd_summary
WHERE msisdn_1 = ? OR msisdn_2 = ?
```

匹配到的线索 ID 自动去重（同一手机号匹配到的重复 ID 只计一次），且 ID 规范化为小号在前格式。

## 输出文件

| 文件 | 说明 |
|------|------|
| `msisdn_score_matched.xlsx` | 输入文件 + E列(匹配数) + F列(匹配ID逗号分隔) |
| `id-export.xlsx` | 所有匹配线索的完整数据（24列） |

### id-export.xlsx 字段列表

| # | 字段名 | 说明 |
|---|--------|------|
| 1 | 线索ID | 规范格式（小号-大号-日期） |
| 2 | 类型 | |
| 3 | 线索等级 | 优先 workflow_state.level，其次 grjd_distribute.level |
| 4 | 号码1 | |
| 5 | 号码2 | |
| 6 | 分数 | |
| 7 | 状态 | 待核查 / 已反馈 / 已处置 |
| 8 | 分配 | |
| 9 | 分配负责人 | |
| 10 | 标记 | |
| 11 | 前科类型 | |
| 12 | 属地 | |
| 13 | 短信全文 | |
| 14 | AI总结 | |
| 15 | 备注 | |
| 16 | 额外信息 | |
| 17 | 数据日期 | |
| 18 | 更新时间 | |
| 19 | 最新反馈 | |
| 20 | 最新反馈时间 | |
| 21 | 最新反馈人 | |
| 22 | 详情压缩 | 全部字段的 key: value 多行文本 |
| 23 | 历史反馈压缩 | 历史反馈记录多行文本 |
| 24 | 上下文短信压缩 | 关联短信多行文本 |

## 编译

```powershell
cd scripts\liukou
go build -o msisdn_matcher.exe .
```

## 运行

```powershell
cd scripts\liukou
.\msisdn_matcher.exe -xlsx msisdn_score.xlsx -workers 8
```

参数说明：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-xlsx` | `msisdn_score.xlsx` | 输入 Excel 文件路径 |
| `-workers` | `8` | 并发查询 Worker 数量（建议 4-16） |

## 性能

- 8 Worker 并发查询，每个手机号独立查库
- 数十万条数据预计耗时取决于数据库响应速度（单次查询约 1-10ms）
- 匹配完成后批量加载完整数据（一次查询），非逐条加载

## 数据库配置

脚本从 `config/prism-config.json` 读取 MySQL DSN，查找顺序：

1. 环境变量 `PRISM_CONFIG_PATH`
2. `../../config/prism-config.json`（从 `scripts/liukou` 相对项目根）
3. `../config/prism-config.json`
4. `config/prism-config.json`
