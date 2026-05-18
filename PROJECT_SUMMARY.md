# Prism 项目总结（面向新成员）

## 项目定位
Prism 是一个面向高风险通信线索的研判与处置系统，目标是把“线索采集 -> 风险识别 -> 人工研判 -> 分配处置 -> 反馈追踪”做成可落地闭环。

系统由三部分组成：
- 后端：Go + MySQL，负责多库路由、工作流状态管理、导入与同步
- 前端：React + TypeScript + Ant Design，提供线索工作台、数据库管理、研判助手、总览看板
- 数据层：sdata 与 wxzdb 分库，主线索数据与业务工作流分离

## 历史改造主线（已完成）

### 1. 数据库键名体系迁移（去兼容化）
- 旧键 core/external 全面切换为 sdata/wxzdb
- 配置白名单、接口参数校验、前端类型一起迁移
- 不保留向后兼容分支，减少双轨逻辑

### 2. 线索分配与等级能力落地
- 新增表 grjd_distribute
- workflow_state 增加 distribute 字段
- 建立同步关系：
  - grjd_distribute.tag -> workflow_state.distribute
  - grjd_distribute.level -> workflow_state.level

### 3. 表结构清理与统一
- grjd_distribute.fxdj 重命名为 level
- workflow_state.claimed_by 删除
- 一次性准备脚本同步升级，支持新结构初始化

### 4. 前端线索工作台增强
- 新增“分配”列及分配筛选
- 筛选栏布局压缩，容纳新增筛选条件
- 保持详情面板与列表字段对齐，避免展示不一致

### 5. 同步机制升级：应用层同步 -> 触发器主同步
- 由“启动时/读取时同步”升级为“数据库触发器主导同步”
- 新增可迁移 SQL 脚本，支持离线环境一键建触发器
- 同步覆盖 INSERT/UPDATE/DELETE 三类分配变更

### 6. 兜底能力：新增手动导入按钮
- 在数据库管理页新增“一键导入线索分配和等级”
- 当触发器异常、迁移后触发器未部署、或历史数据不一致时，人工一键回填
- 接口返回统计信息（写入/更新、分配同步、等级同步）便于确认结果

## 当前核心数据模型

### 主表（sdata）
- nb_tab_grjd_summary：线索汇总主数据
- nb_tab_grjd_message：原始消息明细

### 业务表（wxzdb）
- nb_tab_grjd_workflow_state：工作流状态（status/level/distribute/remark/mark_tag）
- grjd_distribute：线索分配记录（clue_id/level/tag/assign_to/model_name 等）
- nb_tab_grjd_feedback_history：反馈历史
- feedback2nb_tab_grjd_feedback_history：反馈映射关系

## 当前核心数据流（新人必须掌握）
1. 线索主数据从 sdata.summary/message 读取
2. 工作流状态从 wxzdb.workflow_state 读取与更新
3. 分配与等级由 wxzdb.grjd_distribute 维护
4. 同步策略：
- 主路径：MySQL 触发器自动同步 distribute/level
- 兜底：数据库管理页“手动一键导入线索分配和等级”
5. 反馈写入 feedback_history 后推进 workflow 状态为“已反馈”（遵循已处置保护规则）

## 已具备的产品能力
- 风险总览：趋势、类型分布、评分分布
- 线索工作台：多条件筛选、批量反馈/备注/标记、详情联动
- 研判助手：单案/全量/按日三种范围
- 数据库管理：表浏览、字段筛选、一键导入反馈、一键导入分配与等级

## 已知工程策略与取舍
- 多库分工明确：sdata 放主数据，wxzdb 放业务状态与处置链路
- 触发器负责实时一致性，应用层保留手动兜底导入
- 初始化脚本覆盖新环境，迁移脚本照顾旧结构升级
- 对失败提示增强：导入失败可展示后端真实错误信息，便于定位

## 当前状态
- 关键迁移、同步改造、前端功能增强均已完成
- 代码已通过后端编译和前端构建验证
- 系统进入“可运行、可迁移、可兜底”的稳定阶段

## 新人上手建议（1 小时）
1. 先读配置与路由入口，理解分库和接口映射
2. 再看三张关键业务表关系：summary、workflow_state、grjd_distribute
3. 跑通两个核心页面：
- /clues（业务主操作）
- /database（数据核验与导入兜底）
4. 最后验证一次端到端流程：
- 写入或更新 grjd_distribute -> 观察 workflow_state 是否同步
- 若不同步，用“一键导入线索分配和等级”回填并核验统计结果
