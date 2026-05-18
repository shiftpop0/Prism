# Prism 迁移与修复任务清单

- [x] 1. 迁移 sdata/wxzdb 到 127.0.0.1:13306（root/rootroot），建库并导入数据，更新项目数据库连接配置
- [x] 2. 同步数据库初始化代码（sdata.nb_tab_grjd_summary 增加 region/info；wxzdb.grjd_distribute 增加 dt），并移除数据库管理页“一键新建 nb_tab_grjd_workflow_state”
- [x] 3. 修复风险总览统计错误（高风险对象/新增线索/待核查及评分分布、线索等级分布、涉未成年占比受 20 条上限影响）
- [x] 4. 在线索工作台“查看所有上下文短信”弹窗中，将发送方=号码1 的行设置淡色背景
- [x] 5. 线索池增加“短信全文”字段（映射 sdata.nb_tab_grjd_summary.message，支持省略+点击放大）
- [x] 6. 线索池增加“属地”字段（映射 sdata.nb_tab_grjd_summary.region），并加入筛选
- [x] 7. 线索详情 AI 总结下方增加“额外信息”字段（映射 sdata.nb_tab_grjd_summary.info）
- [x] 8. 线索池增加“分配负责人”字段（映射 wxzdb.grjd_distribute.assign_to）
- [x] 9. 修复 sdata.nb_tab_grjd_summary.type 为空导致报错的问题，并做同类空值防护
- [x] 10. 反馈功能增加反馈人填写且必填
- [x] 11. 每次访问线索工作台时自动执行一次“导入线索分配和等级”同步

## 完成记录
- 2026-05-17：
- 已将 `config/prism-config.json` 中 `mysql.dsn`、`external_mysql.dsn` 统一切换至 `127.0.0.1:13306`（`root/rootroot`）。
- 已在目标库校验结构：`sdata.nb_tab_grjd_summary` 含 `region`、`info`；`wxzdb.grjd_distribute` 含 `dt`。
- 已同步数据库初始化代码并修复初始化 SQL 乱码导致的启动失败（MySQL 5.7 兼容）。
- 已移除数据库管理页“一键新建 nb_tab_grjd_workflow_state”按钮。
- 风险总览已改为分页拉全量线索（每页 200）后统计，消除 20 条上限影响。
- 线索工作台已完成：短信弹窗发件方=号码1高亮、短信全文列+放大、属地列+筛选、额外信息展示、分配负责人列、反馈人必填。
- 已实现“每次访问线索工作台自动同步分配和等级”：`/api/v1/clues` 入口触发同步。
- 验证通过：`go test ./cmd/server`、`npm run build`、后端接口联调（`/api/v1/clues`、`/api/v1/dashboard/*`）。

