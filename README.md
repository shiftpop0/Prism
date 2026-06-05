# Prism App (Dev Bootstrap)

## 0. 一键启动（推荐）

在 Windows 下执行：

```powershell
cd .\prism-app
.\start-prism.ps1
```

或双击：

```text
start-prism.bat
```

脚本会自动处理：
- 检查并尝试启动 MySQL（未监听 3306 时尝试拉起常见服务名）
- 若无服务权限，会回退为直接启动 mysqld 进程（无需管理员）
- 判断后端是否已启动（已启动则跳过）
- 判断端口冲突（被占用但服务不可用会直接报错）
- 自动启动前端和后端并输出入口地址

默认入口：
- 前端: http://127.0.0.1:5173
- 后端健康检查: http://127.0.0.1:8081/api/v1/health
- 后端 API 前缀: http://127.0.0.1:8081/api/v1

## 1. Backend (Go)

```powershell
cd backend
go run .\cmd\server
```

Optional environment:

```powershell
$env:SERVER_ADDR=":8080"
$env:MYSQL_DSN="root:YourStrongPassword@tcp(127.0.0.1:3306)/prism?charset=utf8mb4&parseTime=True&loc=Local"
```

## 2. MySQL init

```powershell
mysql -u root -p < .\backend\sql\001_init.sql
```

## 3. Frontend (React + Vite)

```powershell
cd frontend
npm install
npm run dev
```

If `npm` is not found in current shell, open a new terminal session and retry.

## 4. Available pages

- `/` 首页总览（访问时自动触发线索分配与等级同步 + 反馈导入）
- `/clues` 个人极端线索
- `/dialogue` 智能体对话
- `/database` 数据库管理（含一键导入反馈、手动导入反馈 Excel、一键导入线索分配和等级）

## 5. 研判助手提示词模板配置

研判助手系统提示词从 `config/prism-config.json` 读取：

```json
"dialogue": {
  "system_prompt_template": "你是研判助手Agent...\\n分析范围: {{scope}}\\n指定日期: {{day}}\\n分析快照(JSON): {{snapshot}}"
}
```

可用占位符：
- `{{scope}}`：分析范围（`single`/`all`/`day`）
- `{{day}}`：指定日期（按日范围时为 `YYYY-MM-DD`，否则为 `-`）
- `{{snapshot}}`：后端生成的受限快照 JSON

修改配置后重启后端即可生效。

## 6. 更新记录

- **2026-06-06** 新增 `scripts/liukou/` 手机号线索匹配导出工具：多线程（默认 8 Worker）并发查询 `nb_tab_grjd_summary`，按 `msisdn_1`/`msisdn_2` 精确匹配，输出匹配数及 ID 列表写入 Excel，并批量导出匹配线索完整数据（24 列，与系统导出格式一致），支持双数据库（sdata+wxzdb）连接；修复 `syncAllWithCache` TOCTOU 并发问题（新增 `syncRunning` 乐观锁，cron 检测冲突自动跳过）；修复 Excel 手动导入反馈多项缺陷：移除 `<9` 列限制、新增空白行静默跳过、清理未用变量；修复 Level 3 线索 ID 匹配（改用 `id LIKE '号码a-号码b-%'` 前缀查询）；修复 `normalizeDateToCompact` 斜杠日期格式支持（`2024/06/15`、`2024/06/15 10:30:00`）；Excel 导入模板优化：表头标注可空字段、新增 5 种推送时间格式演示行。

- **2026-06-05** 新增线索筛选导出功能；数据库迁移至本地独立实例（sdata → MySQL 5.7 :13307, wxzdb → MySQL 8.0 :13306）；修复线索池排序滞后问题（stale closure）；后端补充 `update_time` 排序显式分支；`.mysql/` 加入 `.gitignore`；重构自动同步机制：导入线索分配和等级同步从线索工作台迁至首页访问触发，新增每日 8:30 定时任务（后台 cron goroutine）；一键导入反馈增加 `appEname='grjdmxjg'` 查询过滤，同步纳入首页触发与定时任务；数据库管理新增"手动导入反馈"功能，支持 Excel 上传与模板下载，含三级线索 ID 智能匹配（直匹 → 号码+日期构造 → 号码模糊匹配）。
