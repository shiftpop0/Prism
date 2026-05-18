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

- `/` 首页总览
- `/clues` 个人极端线索
- `/dialogue` 智能体对话

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
