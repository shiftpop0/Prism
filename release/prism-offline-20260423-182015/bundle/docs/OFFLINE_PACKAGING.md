# Prism 离线迁移与打包方案

## 目标
- 把项目完整迁移到离线环境并可运行。
- 数据库实例由离线环境自行提供，不要求迁移现有数据库数据。

## 方案概览
- 构建阶段（联网或内网开发机执行）：
1. 编译后端 `server.exe`。
2. 构建前端静态文件 `frontend/dist`。
3. 生成前端离线静态服务脚本（独立进程，代理到后端）。
4. 打包 Node.js 离线运行时（安装包 + 便携版）。
5. 复制运行所需配置与脚本。
6. 产出离线压缩包（zip）。
- 运行阶段（离线机执行）：
1. 解压离线包。
2. 按离线数据库地址修改 `config/prism-config.json`。
3. 双击 `start-offline.bat` 或执行 `start-offline.ps1`，后台启动前后端。
4. 执行 `stop-offline.bat` 或 `stop-offline.ps1` 一键停止。

## 一键打包
在项目根目录执行：

```powershell
cd .\prism-app
.\scripts\package-offline.ps1
```

打包输出：
- 目录：`prism-app/release/prism-offline-时间戳/bundle`
- 压缩包：`prism-app/release/prism-offline-时间戳/prism-offline-时间戳.zip`

可选参数：

```powershell
.\scripts\package-offline.ps1 -SkipFrontendBuild
.\scripts\package-offline.ps1 -SkipBackendBuild
.\scripts\package-offline.ps1 -OutputDir .\release -BundleName prism-offline-v1
.\scripts\package-offline.ps1 -BackendServerAddr :8090
.\scripts\package-offline.ps1 -BackendServerAddr :8090 -FrontendPort 5175
.\scripts\package-offline.ps1 -SkipNodeRuntime
.\scripts\package-offline.ps1 -NodeVersion v20.11.1
```

端口说明：
- 离线包启动时会分别运行：
  - 后端服务（`backend/server.exe`）
  - 前端静态服务（`frontend/server.js`，并将 `/api/*` 代理到后端）
- `-BackendServerAddr` 用于直接写入离线包配置中的后端监听地址。
- `-FrontendPort` 用于直接写入离线包配置中的前端监听端口。
- 默认端口：后端 `:8081`，前端 `5173`。
- 端口优先级（高到低）：
  - 运行时参数：`start-offline.ps1 -BackendServerAddr ... -FrontendPort ...`
  - 配置文件：`config/prism-config.json` 中 `backend.server_addr` / `frontend.port`
  - 默认值：`backend=:8081`、`frontend=5173`

## 离线包内容
- `backend/server.exe`：后端可执行文件。
- `frontend/dist`：前端静态页面。
- `frontend/server.js`：前端离线静态服务（含 API 代理）。
- `runtime/node-installer/*.msi|*.zip`：Node.js 离线安装包。
- `runtime/node-portable/**/node.exe`：Node.js 便携运行时（默认优先使用）。
- `config/prism-config.json`：运行配置。
- `install-node-offline.ps1`：Node 离线安装辅助脚本。
- `start-offline.ps1` / `start-offline.bat`：后台启动脚本。
- `stop-offline.ps1` / `stop-offline.bat`：一键停止脚本。
- `docs/*`：文档副本。

## 离线环境前置条件
- Windows x64。
- 可访问目标 MySQL（本机或内网地址均可）。
- 可选：安装 Node.js（默认可直接使用包内便携版，无需安装）。
- 放通后端端口（默认 `8081`）和前端端口（默认 `5173`）。

说明：
- 当前离线方案为前后端独立端口运行，前端服务通过本地代理访问后端 API。
- 单案快照已改为后端内置查询，不依赖 `go run`。

## 离线运行步骤
1. 解压压缩包到任意目录（例如 `D:\prism-offline`）。
2. 编辑 `config/prism-config.json`：
   - `mysql.dsn` 指向离线环境 `sdata`。
   - `external_mysql.dsn` 指向离线环境 `wxzdb`（如果分库部署）。
   - `llm` 配置按离线可用模型网关填写。
3. 启动：
   - 双击 `start-offline.bat`
   - 或 PowerShell 执行：`.\start-offline.ps1`
   - 临时覆盖端口：`.\start-offline.ps1 -BackendServerAddr :8090 -FrontendPort 5175`
   - 可选安装 Node（MSI 静默安装）：`.\install-node-offline.ps1 -Mode msi`
   - 可选验证便携 Node：`.\install-node-offline.ps1 -Mode portable`
4. 访问：
   - 前端：`http://127.0.0.1:5173`（若自定义则按 `FrontendPort`）
   - 后端健康检查：`http://127.0.0.1:8081/api/v1/health`（若自定义则按 `BackendServerAddr`）
5. 停止：
   - 双击 `stop-offline.bat`
   - 或 PowerShell 执行：`.\stop-offline.ps1`

## 验证清单
- 前端页面可打开，路由跳转正常（`/clues`、`/dialogue`、`/database`）。
- `api/v1/health` 返回 `code=0`。
- 线索列表可查询。
- 研判助手可正常生成回答。


## 日志查看
- 后端日志：`./run/backend.log`
- 前端日志：`./run/frontend.log`
- 实时查看后端：`Get-Content .\run\backend.log -Wait`
- 实时查看前端：`Get-Content .\run\frontend.log -Wait`
