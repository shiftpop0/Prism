import { useEffect, useMemo, useState } from 'react'
import { Alert, Button, Card, DatePicker, Descriptions, Input, List, Modal, Select, Space, Tag, Typography, message } from 'antd'
import dayjs from 'dayjs'
import {
  fetchDialogueAgentSpec,
  fetchDialogueSnapshot,
  fetchSummaryCases,
  sendDialogueMessageV2,
  type DialogueAgentSpec,
  type DialogueData,
  type DialogueRequestOptions,
  type DialogueSnapshotData,
  type SummaryCase,
} from '../api/client'

const { Text, Title, Paragraph } = Typography
const { TextArea } = Input

type Scope = 'single' | 'all' | 'day'
type ChatRole = 'user' | 'assistant'

interface ChatMessage {
  id: string
  role: ChatRole
  content: string
  citations?: DialogueData['citations']
}

function DialoguePage() {
  const [scope, setScope] = useState<Scope>('single')
  const [focusId, setFocusId] = useState('')
  const [selectedDate, setSelectedDate] = useState(dayjs())
  const [inputText, setInputText] = useState('')
  const [sending, setSending] = useState(false)
  const [loadingSnapshot, setLoadingSnapshot] = useState(false)
  const [agentSpec, setAgentSpec] = useState<DialogueAgentSpec | null>(null)
  const [snapshot, setSnapshot] = useState<DialogueSnapshotData | null>(null)
  const [showSnapshotModal, setShowSnapshotModal] = useState(false)
  const [clueOptions, setClueOptions] = useState<Array<{ value: string; label: string }>>([])
  const [clueRows, setClueRows] = useState<SummaryCase[]>([])
  const [messages, setMessages] = useState<ChatMessage[]>([])

  const requestOptions = useMemo<DialogueRequestOptions>(() => {
    if (scope === 'day') {
      return { scope, date: selectedDate.format('YYYY-MM-DD') }
    }
    if (scope === 'single') {
      return { scope, focusId: focusId.trim() }
    }
    return { scope }
  }, [focusId, scope, selectedDate])

  const scopeLabel = scope === 'single' ? '单案' : scope === 'day' ? '按日' : '全量'

  const formatClueOption = (item: SummaryCase) => ({
    value: item.id,
    label: `${item.id} ｜ ${item.type || '-'} ｜ ${item.msisdn_1 || '-'} / ${item.msisdn_2 || '-'}`,
  })

  const refreshSnapshot = async () => {
    if (scope === 'single' && !focusId.trim()) {
      setSnapshot(null)
      return
    }
    try {
      setLoadingSnapshot(true)
      const data = await fetchDialogueSnapshot(requestOptions)
      setSnapshot(data)
      console.log('[dialogue] system_prompt:', data.system_prompt)
    } catch {
      setSnapshot(null)
      message.error('案件快照加载失败，请稍后重试')
    } finally {
      setLoadingSnapshot(false)
    }
  }

  const openSnapshotModal = async () => {
    if (!snapshot) {
      await refreshSnapshot()
    }
    setShowSnapshotModal(true)
  }

  const prettySnapshot = useMemo(() => {
    if (!snapshot?.snapshot) return ''
    try {
      return JSON.stringify(JSON.parse(snapshot.snapshot), null, 2)
    } catch {
      return snapshot.snapshot
    }
  }, [snapshot])

  const selectedClue = useMemo(
    () => clueRows.find((row) => row.id === focusId),
    [clueRows, focusId],
  )

  const parsedSnapshot = useMemo<Record<string, unknown> | null>(() => {
    if (!snapshot?.snapshot) return null
    try {
      return JSON.parse(snapshot.snapshot) as Record<string, unknown>
    } catch {
      return null
    }
  }, [snapshot])

  const sendMessage = async (rawText?: string) => {
    const text = (rawText ?? inputText).trim()
    if (!text) {
      message.warning('请输入问题')
      return
    }
    if (scope === 'single' && !focusId.trim()) {
      message.warning('单案模式请先输入线索ID')
      return
    }

    const userMsg: ChatMessage = {
      id: `u_${Date.now()}`,
      role: 'user',
      content: text,
    }
    const placeholderId = `a_${Date.now()}`
    const placeholder: ChatMessage = {
      id: placeholderId,
      role: 'assistant',
      content: '正在生成分析结果...',
    }
    setMessages((prev) => [...prev, userMsg, placeholder])
    setSending(true)
    setInputText('')
    try {
      const data = await sendDialogueMessageV2(text, requestOptions)
      setMessages((prev) => prev.map((item) => (item.id === placeholderId
        ? {
          id: placeholderId,
          role: 'assistant',
          content: data.answer || '未返回内容',
          citations: data.citations,
        }
        : item)))
      void refreshSnapshot()
    } catch {
      setMessages((prev) => prev.map((item) => (item.id === placeholderId
        ? {
          id: placeholderId,
          role: 'assistant',
          content: '调用失败，请检查后端服务、模型配置和网络后重试。',
        }
        : item)))
      message.error('发送失败，请稍后重试')
    } finally {
      setSending(false)
    }
  }

  useEffect(() => {
    fetchDialogueAgentSpec()
      .then(setAgentSpec)
      .catch(() => setAgentSpec(null))
    fetchSummaryCases()
      .then((res) => {
        setClueRows(res.list)
        setClueOptions(res.list.slice(0, 1000).map(formatClueOption))
      })
      .catch(() => setClueOptions([]))
  }, [])

  useEffect(() => {
    void refreshSnapshot()
  }, [scope, selectedDate, focusId])

  return (
    <div className="prism-page dialogue-page">
      <div className="dialogue-hero">
        <div>
          <Title level={4} style={{ margin: 0 }}>研判助手</Title>
          <Text type="secondary">仅允许基于受限快照字段输出结论</Text>
        </div>
        <Space>
          <Button className="dialogue-spec-btn" onClick={() => void refreshSnapshot()} loading={loadingSnapshot}>
            刷新快照
          </Button>
          <Button className="dialogue-spec-btn" onClick={() => void openSnapshotModal()}>
            查看快照与提示词
          </Button>
        </Space>
      </div>

      <Card className="panel-card dialogue-control-card" style={{ marginBottom: 14 }}>
        <Space wrap>
          <Select<Scope>
            value={scope}
            style={{ width: 130 }}
            onChange={setScope}
            options={[
              { value: 'single', label: '单案' },
              { value: 'all', label: '全量' },
              { value: 'day', label: '按日' },
            ]}
          />
          {scope === 'single' ? (
            <Select
              showSearch
              allowClear
              optionFilterProp="label"
              style={{ width: 420 }}
              value={focusId}
              onChange={(value) => setFocusId(value || '')}
              placeholder="请选择或搜索线索ID"
              options={clueOptions}
            />
          ) : null}
          {scope === 'day' ? (
            <DatePicker
              value={selectedDate}
              onChange={(v) => setSelectedDate(v || dayjs())}
              allowClear={false}
              format="YYYY-MM-DD"
            />
          ) : null}
          <Tag color="processing">当前范围：{scopeLabel}</Tag>
        </Space>
      </Card>

      <div className="dialogue-layout">
        <Card className="panel-card dialogue-side-card" title="线索概要与快捷问题">
          <Card size="small" className="dialogue-case-summary" title="线索概要">
            {scope === 'single' ? (
              selectedClue ? (
                <Descriptions size="small" column={1} colon={false}>
                  <Descriptions.Item label="线索ID">{selectedClue.id}</Descriptions.Item>
                  <Descriptions.Item label="类型">{selectedClue.type || '-'}</Descriptions.Item>
                  <Descriptions.Item label="分数">{selectedClue.score ?? '-'}</Descriptions.Item>
                  <Descriptions.Item label="状态">{selectedClue.status || '-'}</Descriptions.Item>
                  <Descriptions.Item label="分配">{selectedClue.distribute || '-'}</Descriptions.Item>
                </Descriptions>
              ) : (
                <Text type="secondary">请选择一条线索查看概要</Text>
              )
            ) : (
              <Descriptions size="small" column={1} colon={false}>
                <Descriptions.Item label="范围">{scopeLabel}</Descriptions.Item>
                <Descriptions.Item label="总量">{String(parsedSnapshot?.total ?? '-')}</Descriptions.Item>
                <Descriptions.Item label="高风险">{String(parsedSnapshot?.high_risk_count ?? '-')}</Descriptions.Item>
                <Descriptions.Item label="均分">{String(parsedSnapshot?.avg_score ?? '-')}</Descriptions.Item>
              </Descriptions>
            )}
          </Card>
          {agentSpec?.quick_prompts?.length ? (
            <Space direction="vertical" size={8} style={{ width: '100%', marginTop: 12 }}>
              {agentSpec.quick_prompts.map((prompt) => (
                <Button key={prompt} className="dialogue-prompt-btn" onClick={() => void sendMessage(prompt)}>
                  {prompt}
                </Button>
              ))}
            </Space>
          ) : null}
          {!agentSpec?.quick_prompts?.length ? (
            <Alert type="info" showIcon message="暂无快捷问题" />
          ) : null}
        </Card>

        <Card className="panel-card dialogue-main-card" title="对话">
          <div className="dialogue-chat-scroll">
            <List
              className="dialogue-chat-card"
              dataSource={messages}
              locale={{ emptyText: '请输入问题开始研判' }}
              renderItem={(item) => (
                <List.Item key={item.id} className={`dialogue-msg-row ${item.role}`}>
                  <div className="dialogue-msg-bubble">
                    <Text strong>{item.role === 'user' ? '你' : '助手'}：</Text>
                    <Text style={{ whiteSpace: 'pre-wrap' }}>{item.content}</Text>
                    {item.citations?.length ? (
                      <div style={{ marginTop: 8 }}>
                        <Text type="secondary">引用：</Text>
                        {item.citations.map((c) => (
                          <Tag key={c.evidence_id}>{c.title}</Tag>
                        ))}
                      </div>
                    ) : null}
                  </div>
                </List.Item>
              )}
            />
          </div>
          <div className="dialogue-composer">
            <TextArea
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="请输入你的研判问题..."
              rows={4}
              onPressEnter={(e) => {
                if (!e.shiftKey) {
                  e.preventDefault()
                  void sendMessage()
                }
              }}
            />
            <div className="dialogue-send-row">
              <Text type="secondary">Enter 发送，Shift+Enter 换行</Text>
              <Button type="primary" loading={sending} onClick={() => void sendMessage()}>
                发送
              </Button>
            </div>
          </div>
        </Card>
      </div>

      <Modal
        title="案件快照与提示词"
        open={showSnapshotModal}
        onCancel={() => setShowSnapshotModal(false)}
        footer={null}
        width={980}
      >
        {!snapshot ? (
          <Alert type="info" showIcon message="尚未加载快照" description="单案模式下请先选择线索ID。" />
        ) : (
          <Space direction="vertical" size={12} style={{ width: '100%' }}>
            <Card size="small" className="dialogue-case-summary" title={snapshot.title}>
              <Text type="secondary">来源：{snapshot.source}</Text>
              {snapshot.focus_id ? (
                <div>
                  <Text type="secondary">线索ID：{snapshot.focus_id}</Text>
                </div>
              ) : null}
              <Paragraph code style={{ marginTop: 8, whiteSpace: 'pre-wrap', maxHeight: 360, overflow: 'auto' }}>
                {prettySnapshot}
              </Paragraph>
            </Card>
            <Card size="small" className="dialogue-case-summary" title="系统提示词（来自配置）">
              <Paragraph style={{ marginBottom: 0, whiteSpace: 'pre-wrap', maxHeight: 260, overflow: 'auto' }}>
                {snapshot.system_prompt}
              </Paragraph>
            </Card>
          </Space>
        )}
      </Modal>
    </div>
  )
}

export default DialoguePage
