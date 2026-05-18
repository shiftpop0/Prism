import {
  Button,
  Card,
  Checkbox,
  ConfigProvider,
  DatePicker,
  Descriptions,
  Divider,
  Input,
  InputNumber,
  Modal,
  Popover,
  Select,
  Slider,
  Space,
  Table,
  Tag,
  Typography,
  message,
  type TableColumnsType,
  type TableProps,
} from 'antd'
import type { HTMLAttributes, ReactNode } from 'react'
import zhCN from 'antd/locale/zh_CN'
import dayjs, { type Dayjs } from 'dayjs'
import 'dayjs/locale/zh-cn'
import { useEffect, useMemo, useRef, useState } from 'react'
import {
  fetchCaseMessages,
  fetchClueDetail,
  fetchClueFeedbacks,
  fetchClueFilterOptions,
  fetchSummaryCases,
  type CaseDetail,
  type FeedbackHistoryItem,
  type MessageCase,
  type SummaryCase,
  updateClueAction,
} from '../api/client'

dayjs.locale('zh-cn')
const { Title, Text } = Typography
const { RangePicker } = DatePicker

type ClueSortBy =
  | 'msisdn_1'
  | 'msisdn_2'
  | 'type'
  | 'region'
  | 'qklx'
  | 'level'
  | 'assign_to'
  | 'score'
  | 'update_time'
  | 'status'
  | 'distribute'
type ClueSortOrder = 'asc' | 'desc'

function formatScore(v: unknown) {
  const n = Number(v)
  return Number.isFinite(n) ? n.toFixed(2) : '-'
}

function defaultColWidth(title: string) {
  return Math.max(110, String(title).length * 16 + 40)
}

function renderTruncText(title: string, value?: string | null, onPreview?: (title: string, text: string) => void, width?: number) {
  const text = value && value.trim() ? value : '-'
  const effectiveWidth = Math.max(80, Number(width || 120))
  const maxChars = Math.max(6, Math.floor((effectiveWidth - 28) / 13))
  const isOverflow = text.length > maxChars
  return (
    <span
      className={`db-cell-trunc${isOverflow ? ' is-truncated' : ''}`}
      onClick={isOverflow ? () => onPreview?.(title, text) : undefined}
    >
      {text}
    </span>
  )
}

type ResizeHeaderCellProps = HTMLAttributes<HTMLElement> & {
  children?: ReactNode
  onResizeStart?: (e: React.MouseEvent) => void
}

function ResizeHeaderCell({ children, onResizeStart, className, ...rest }: ResizeHeaderCellProps) {
  return (
    <th className={className} {...rest}>
      <div className="clues-header-cell-wrap">{children}</div>
      {onResizeStart ? <span className="clues-col-resize-handle" onMouseDown={onResizeStart} /> : null}
    </th>
  )
}

function CluesPage() {
  const [rows, setRows] = useState<SummaryCase[]>([])
  const [totalRows, setTotalRows] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [loading, setLoading] = useState(false)

  const [selectedId, setSelectedId] = useState('')
  const [selectedRowKeys, setSelectedRowKeys] = useState<string[]>([])
  const [detail, setDetail] = useState<CaseDetail | null>(null)

  const [keyword, setKeyword] = useState('')
  const [statusFilter, setStatusFilter] = useState<string | undefined>()
  const [markFilter, setMarkFilter] = useState<string | undefined>()
  const [distributeFilter, setDistributeFilter] = useState<string | undefined>()
  const [regionFilter, setRegionFilter] = useState<string | undefined>()
  const [scoreRange, setScoreRange] = useState<[number, number]>([0, 1])
  const [dateRange, setDateRange] = useState<[Dayjs | null, Dayjs | null]>([
    dayjs().subtract(1, 'day'),
    dayjs().subtract(1, 'day'),
  ])
  const [sortBy, setSortBy] = useState<ClueSortBy>('update_time')
  const [sortOrder, setSortOrder] = useState<ClueSortOrder>('desc')

  const [statusOptions, setStatusOptions] = useState<Array<{ label: string; value: string }>>([])
  const [distributeOptions, setDistributeOptions] = useState<Array<{ label: string; value: string }>>([
    { value: '__EMPTY__', label: '空（未分配）' },
  ])
  const [regionOptions, setRegionOptions] = useState<Array<{ label: string; value: string }>>([
    { value: '__EMPTY__', label: '空（未填写属地）' },
  ])

  const [messagesOpen, setMessagesOpen] = useState(false)
  const [messagesData, setMessagesData] = useState<MessageCase[]>([])
  const [feedbackHistoryOpen, setFeedbackHistoryOpen] = useState(false)
  const [feedbackHistoryData, setFeedbackHistoryData] = useState<FeedbackHistoryItem[]>([])
  const [feedbackHistoryId, setFeedbackHistoryId] = useState('')

  const [feedbackModalOpen, setFeedbackModalOpen] = useState(false)
  const [feedbackInput, setFeedbackInput] = useState('')
  const [feedbackUser, setFeedbackUser] = useState('')
  const [feedbackTargetIds, setFeedbackTargetIds] = useState<string[]>([])
  const [feedbackHistoryInEditor, setFeedbackHistoryInEditor] = useState<FeedbackHistoryItem[]>([])
  const [feedbackHistoryLoading, setFeedbackHistoryLoading] = useState(false)

  const [inputOpen, setInputOpen] = useState(false)
  const [inputAction, setInputAction] = useState<'remark' | 'mark'>('remark')
  const [inputValue, setInputValue] = useState('')
  const [actionIds, setActionIds] = useState<string[]>([])

  const [previewOpen, setPreviewOpen] = useState(false)
  const [previewTitle, setPreviewTitle] = useState('字段内容')
  const [previewText, setPreviewText] = useState('')

  const [leftPanelWidth, setLeftPanelWidth] = useState(60)
  const [isResizingPanels, setIsResizingPanels] = useState(false)
  const splitWrapRef = useRef<HTMLDivElement | null>(null)

  const [columnWidths, setColumnWidths] = useState<Record<string, number>>({})
  const [resizingCol, setResizingCol] = useState<string | null>(null)
  const resizeRef = useRef<{ key: string; startX: number; startWidth: number } | null>(null)

  const [visibleColumnKeys, setVisibleColumnKeys] = useState<string[]>([
    'msisdn_1',
    'msisdn_2',
    'type',
    'region',
    'qklx',
    'message',
    'level',
    'assign_to',
    'score',
    'update_time',
    'status',
    'distribute',
    'action',
  ])

  const markOptions = useMemo(
    () => [
      { value: '', label: '空（无标记）' },
      { value: 'red', label: '红色重点' },
      { value: 'orange', label: '橙色关注' },
      { value: 'gold', label: '黄色观察' },
      { value: 'blue', label: '蓝色跟进' },
      { value: 'green', label: '绿色已稳' },
      { value: 'purple', label: '紫色复核' },
    ],
    [],
  )

  const markFilterOptions = useMemo(
    () => [
      { value: '__EMPTY__', label: '空（无标记）' },
      ...markOptions.filter((x) => x.value).map((x) => ({ value: x.value, label: x.label })),
    ],
    [markOptions],
  )

  const loadRows = async (p = currentPage, ps = pageSize) => {
    setLoading(true)
    try {
      const data = await fetchSummaryCases({
        keyword: keyword.trim() || undefined,
        page: p,
        pageSize: ps,
        sortBy,
        sortOrder,
        status: statusFilter,
        markTag: markFilter,
        distribute: distributeFilter,
        region: regionFilter,
        scoreMin: scoreRange[0],
        scoreMax: scoreRange[1],
        dataDateFrom: dateRange[0]?.format('YYYY-MM-DD'),
        dataDateTo: dateRange[1]?.format('YYYY-MM-DD'),
      })
      setRows(data.list)
      setTotalRows(data.total)
      setCurrentPage(data.page)
      setPageSize(data.page_size)
      if (selectedId && !data.list.some((x) => x.id === selectedId)) {
        setSelectedId('')
        setDetail(null)
      }
    } catch {
      message.error('加载线索失败')
      setRows([])
      setTotalRows(0)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadRows(1, pageSize)
    fetchClueFilterOptions()
      .then((r) => {
        setStatusOptions((r.status_options || []).map((x) => ({ label: x, value: x })))
        setDistributeOptions([
          { value: '__EMPTY__', label: '空（未分配）' },
          ...(r.distribute_options || []).map((x) => ({ label: x, value: x })),
        ])
        setRegionOptions([
          { value: '__EMPTY__', label: '空（未填写属地）' },
          ...(r.region_options || []).map((x) => ({ label: x, value: x })),
        ])
      })
      .catch(() => {})
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (!selectedId) {
      setDetail(null)
      return
    }
    fetchClueDetail(selectedId)
      .then(setDetail)
      .catch(() => setDetail(null))
  }, [selectedId])

  useEffect(() => {
    if (!isResizingPanels) return
    const onMove = (event: MouseEvent) => {
      const wrap = splitWrapRef.current
      if (!wrap) return
      const rect = wrap.getBoundingClientRect()
      if (!rect.width) return
      const ratio = ((event.clientX - rect.left) / rect.width) * 100
      setLeftPanelWidth(Math.max(32, Math.min(78, ratio)))
    }
    const onUp = () => setIsResizingPanels(false)
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [isResizingPanels])

  useEffect(() => {
    if (!resizingCol) return
    const onMove = (event: MouseEvent) => {
      const current = resizeRef.current
      if (!current) return
      const delta = event.clientX - current.startX
      const next = Math.max(80, Math.round(current.startWidth + delta))
      setColumnWidths((prev) => ({ ...prev, [current.key]: next }))
    }
    const onUp = () => {
      resizeRef.current = null
      setResizingCol(null)
    }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [resizingCol])

  const openPreview = (title: string, text: string) => {
    setPreviewTitle(title)
    setPreviewText(text || '-')
    setPreviewOpen(true)
  }

  const openMessages = async () => {
    if (!selectedId) return
    try {
      setMessagesData(await fetchCaseMessages(selectedId))
      setMessagesOpen(true)
    } catch {
      message.error('加载短信失败')
    }
  }

  const openFeedbackHistory = async (id: string) => {
    try {
      const data = await fetchClueFeedbacks(id)
      setFeedbackHistoryId(id)
      setFeedbackHistoryData(data)
      setFeedbackHistoryOpen(true)
    } catch {
      message.error('加载反馈历史失败')
    }
  }

  const openFeedbackEditor = async (ids: string[]) => {
    if (!ids.length) return message.warning('请先选择线索')
    setFeedbackTargetIds(ids)
    setFeedbackInput('')
    setFeedbackUser('')
    setFeedbackModalOpen(true)
    setFeedbackHistoryInEditor([])
    setFeedbackHistoryLoading(true)
    try {
      const data = await fetchClueFeedbacks(ids[0])
      setFeedbackHistoryInEditor(data)
    } catch {
      setFeedbackHistoryInEditor([])
    } finally {
      setFeedbackHistoryLoading(false)
    }
  }

  const saveFeedback = async () => {
    const value = feedbackInput.trim()
    const user = feedbackUser.trim()
    if (!value) return message.warning('请填写反馈内容')
    if (!user) return message.warning('请填写反馈人')
    try {
      await Promise.all(feedbackTargetIds.map((id) => updateClueAction(id, 'feedback', value, user)))
      setFeedbackModalOpen(false)
      setSelectedRowKeys([])
      await loadRows(currentPage, pageSize)
      if (feedbackTargetIds[0]) setSelectedId(feedbackTargetIds[0])
      message.success('反馈成功')
    } catch {
      message.error('反馈失败')
    }
  }

  const openInput = (action: 'remark' | 'mark', ids: string[]) => {
    if (!ids.length) return message.warning('请先选择线索')
    setInputAction(action)
    setActionIds(ids)
    setInputValue('')
    setInputOpen(true)
  }

  const saveInput = async () => {
    const value = inputAction === 'mark' ? inputValue : inputValue.trim()
    try {
      await Promise.all(actionIds.map((id) => updateClueAction(id, inputAction, value)))
      setInputOpen(false)
      setSelectedRowKeys([])
      await loadRows(currentPage, pageSize)
      message.success('保存成功')
    } catch {
      message.error('保存失败')
    }
  }

  const selectAllFiltered = async () => {
    setLoading(true)
    try {
      const first = await fetchSummaryCases({
        keyword: keyword.trim() || undefined,
        page: 1,
        pageSize,
        sortBy,
        sortOrder,
        status: statusFilter,
        markTag: markFilter,
        distribute: distributeFilter,
        region: regionFilter,
        scoreMin: scoreRange[0],
        scoreMax: scoreRange[1],
        dataDateFrom: dateRange[0]?.format('YYYY-MM-DD'),
        dataDateTo: dateRange[1]?.format('YYYY-MM-DD'),
      })
      const total = Number(first.total || 0)
      if (!total) {
        setSelectedRowKeys([])
        return
      }
      const pageCount = Math.ceil(total / pageSize)
      const ids = new Set<string>(first.list.map((item) => item.id))
      if (pageCount > 1) {
        const tasks: Array<Promise<{ list: SummaryCase[] }>> = []
        for (let p = 2; p <= pageCount; p += 1) {
          tasks.push(
            fetchSummaryCases({
              keyword: keyword.trim() || undefined,
              page: p,
              pageSize,
              sortBy,
              sortOrder,
              status: statusFilter,
              markTag: markFilter,
              distribute: distributeFilter,
              region: regionFilter,
              scoreMin: scoreRange[0],
              scoreMax: scoreRange[1],
              dataDateFrom: dateRange[0]?.format('YYYY-MM-DD'),
              dataDateTo: dateRange[1]?.format('YYYY-MM-DD'),
            }),
          )
        }
        const pages = await Promise.all(tasks)
        pages.forEach((pg) => pg.list.forEach((item) => ids.add(item.id)))
      }
      setSelectedRowKeys(Array.from(ids))
      message.success(`已全选筛选结果，共 ${ids.size} 条`)
    } catch {
      message.error('全选筛选结果失败')
    } finally {
      setLoading(false)
    }
  }

  const startColResize = (e: React.MouseEvent, key: string, width: number) => {
    e.preventDefault()
    e.stopPropagation()
    resizeRef.current = { key, startX: e.clientX, startWidth: width }
    setResizingCol(key)
  }

  const allColumns: TableColumnsType<SummaryCase> = [
    { key: 'msisdn_1', title: '号码1', dataIndex: 'msisdn_1', sorter: true, sortOrder: sortBy === 'msisdn_1' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('号码1', v, openPreview, columnWidths.msisdn_1 || defaultColWidth('号码1')) },
    { key: 'msisdn_2', title: '号码2', dataIndex: 'msisdn_2', sorter: true, sortOrder: sortBy === 'msisdn_2' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('号码2', v, openPreview, columnWidths.msisdn_2 || defaultColWidth('号码2')) },
    { key: 'type', title: '类型', dataIndex: 'type', sorter: true, sortOrder: sortBy === 'type' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('类型', v, openPreview, columnWidths.type || defaultColWidth('类型')) },
    { key: 'region', title: '属地', dataIndex: 'region', sorter: true, sortOrder: sortBy === 'region' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('属地', v, openPreview, columnWidths.region || defaultColWidth('属地')) },
    { key: 'qklx', title: '前科类型', dataIndex: 'qklx', sorter: true, sortOrder: sortBy === 'qklx' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('前科类型', v, openPreview, columnWidths.qklx || defaultColWidth('前科类型')) },
    { key: 'message', title: '短信全文', dataIndex: 'message', render: (v?: string) => renderTruncText('短信全文', v, openPreview, columnWidths.message || defaultColWidth('短信全文')) },
    { key: 'level', title: '线索等级', dataIndex: 'level', sorter: true, sortOrder: sortBy === 'level' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('线索等级', v, openPreview, columnWidths.level || defaultColWidth('线索等级')) },
    { key: 'assign_to', title: '分配负责人', dataIndex: 'assign_to', sorter: true, sortOrder: sortBy === 'assign_to' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('分配负责人', v, openPreview, columnWidths.assign_to || defaultColWidth('分配负责人')) },
    { key: 'score', title: '分数', dataIndex: 'score', sorter: true, sortOrder: sortBy === 'score' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v) => formatScore(v) },
    { key: 'update_time', title: '数据日期', dataIndex: 'data_date', sorter: true, sortOrder: sortBy === 'update_time' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (_, r) => renderTruncText('数据日期', r.data_date, openPreview, columnWidths.update_time || defaultColWidth('数据日期')) },
    { key: 'status', title: '状态', dataIndex: 'status', sorter: true, sortOrder: sortBy === 'status' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v: string) => (v === '已反馈' ? <Tag color="green">已反馈</Tag> : <Tag color="blue">{v || '待核查'}</Tag>) },
    { key: 'distribute', title: '分配', dataIndex: 'distribute', sorter: true, sortOrder: sortBy === 'distribute' ? (sortOrder === 'asc' ? 'ascend' : 'descend') : null, render: (v?: string) => renderTruncText('分配', v, openPreview, columnWidths.distribute || defaultColWidth('分配')) },
    { key: 'action', title: '操作', render: (_, r) => <Button type="link" onClick={(e) => { e.stopPropagation(); void openFeedbackEditor([r.id]) }}>反馈</Button> },
  ]

  const mergedColumns = allColumns
    .filter((col) => visibleColumnKeys.includes(String(col.key || '')))
    .map((col) => {
      const key = String(col.key || '')
      const width = columnWidths[key] || defaultColWidth(String(col.title || key))
      return {
        ...col,
        width,
        onHeaderCell: () => ({
          className: `clues-resizable-header${resizingCol === key ? ' is-resizing' : ''}`,
          onResizeStart: (e: React.MouseEvent) => startColResize(e, key, width),
        }),
      }
    })

  const totalX = mergedColumns.reduce((s, col) => s + Number(col.width || 120), 0)
  const columnOptions = allColumns
    .filter((c) => String(c.key) !== 'action')
    .map((c) => ({ label: String(c.title), value: String(c.key) }))

  const onTableChange: TableProps<SummaryCase>['onChange'] = (pagination, _filters, sorter) => {
    const s = Array.isArray(sorter) ? sorter[0] : sorter
    setSortBy((s?.columnKey as ClueSortBy) || 'update_time')
    setSortOrder(s?.order === 'ascend' ? 'asc' : 'desc')
    void loadRows(pagination.current || 1, pagination.pageSize || pageSize)
  }

  return (
    <ConfigProvider locale={zhCN}>
      <div className="prism-page">
        <Title level={4}>线索工作台</Title>

        <Card className="panel-card clues-filter-card" style={{ marginBottom: 14 }}>
          <div className="clues-filter-grid">
            <Input allowClear placeholder="关键词" value={keyword} onChange={(e) => setKeyword(e.target.value)} className="keyword-filter-input" />
            <RangePicker
              value={dateRange}
              onChange={(v) => setDateRange(v ? [v[0], v[1]] : [null, null])}
              placeholder={['开始日期', '结束日期']}
              separator="至"
            />
            <Select allowClear placeholder="状态" value={statusFilter} onChange={setStatusFilter} options={statusOptions} style={{ width: 112 }} />
            <Select allowClear placeholder="标记" value={markFilter} onChange={setMarkFilter} options={markFilterOptions} style={{ width: 112 }} />
            <Select allowClear placeholder="分配" value={distributeFilter} onChange={setDistributeFilter} options={distributeOptions} style={{ width: 112 }} />
            <Select allowClear placeholder="属地" value={regionFilter} onChange={setRegionFilter} options={regionOptions} style={{ width: 112 }} />
            <div className="clues-filter-actions">
              <InputNumber min={0} max={1} step={0.01} value={scoreRange[0]} onChange={(v) => setScoreRange([Number(v ?? 0), scoreRange[1]])} style={{ width: 98 }} placeholder="最小值0.00" />
              <div style={{ width: 110 }}>
                <Slider range min={0} max={1} step={0.01} value={scoreRange} onChange={(v) => setScoreRange(v as [number, number])} />
              </div>
              <InputNumber min={0} max={1} step={0.01} value={scoreRange[1]} onChange={(v) => setScoreRange([scoreRange[0], Number(v ?? 1)])} style={{ width: 98 }} placeholder="最大值1.00" />
              <Button type="primary" onClick={() => void loadRows(1, pageSize)}>查询</Button>
              <Button onClick={() => {
                setKeyword('')
                setStatusFilter(undefined)
                setMarkFilter(undefined)
                setDistributeFilter(undefined)
                setRegionFilter(undefined)
                setDateRange([dayjs().subtract(1, 'day'), dayjs().subtract(1, 'day')])
                setScoreRange([0, 1])
              }}>重置</Button>
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <Space wrap>
              <Text>已选择 {selectedRowKeys.length} 条</Text>
              <Button onClick={() => void selectAllFiltered()}>全选</Button>
              <Button onClick={() => setSelectedRowKeys([])} disabled={!selectedRowKeys.length}>取消全选</Button>
              <Button onClick={() => void openFeedbackEditor(selectedRowKeys)}>批量反馈</Button>
              <Button onClick={() => openInput('remark', selectedRowKeys)}>批量备注</Button>
              <Button onClick={() => openInput('mark', selectedRowKeys)}>批量标记</Button>
            </Space>
          </div>
        </Card>

        <div className="clues-split-wrap" ref={splitWrapRef}>
          <div className="clues-panel-left" style={{ width: `${leftPanelWidth}%` }}>
            <Card
              className="panel-card"
              title={`线索池（共 ${totalRows} 条）`}
              extra={
                <Popover
                  trigger="click"
                  placement="bottomRight"
                  overlayClassName="column-visibility-popover"
                  content={
                    <div className="column-visibility-list">
                      <Checkbox.Group
                        value={visibleColumnKeys.filter((k) => k !== 'action')}
                        onChange={(vals) => setVisibleColumnKeys([...vals.map(String), 'action'])}
                      >
                        {columnOptions.map((opt) => (
                          <Checkbox key={opt.value} value={opt.value} className="column-visibility-item">
                            {opt.label}
                          </Checkbox>
                        ))}
                      </Checkbox.Group>
                    </div>
                  }
                >
                  <Button className="column-visibility-trigger">列显示</Button>
                </Popover>
              }
            >
              <Table
                className="clues-pool-table"
                rowKey="id"
                dataSource={rows}
                loading={loading}
                columns={mergedColumns}
                components={{ header: { cell: ResizeHeaderCell } }}
                tableLayout="fixed"
                scroll={{ x: totalX }}
                pagination={{
                  current: currentPage,
                  total: totalRows,
                  pageSize,
                  showSizeChanger: true,
                  pageSizeOptions: ['10', '20', '50', '100'],
                }}
                onChange={onTableChange}
                onRow={(record) => ({ onClick: () => setSelectedId(record.id) })}
                rowSelection={{ selectedRowKeys, onChange: (keys) => setSelectedRowKeys(keys.map(String)) }}
              />
            </Card>
          </div>

          <div className="clues-splitter" onMouseDown={() => setIsResizingPanels(true)}>
            <div className="clues-splitter-dot" />
          </div>

          <div className="clues-panel-right" style={{ width: `${100 - leftPanelWidth}%` }}>
            <Card className="panel-card clue-detail-card" title="线索详情">
              {!detail ? (
                <Text type="secondary">请选择线索查看详情</Text>
              ) : (
                <Space direction="vertical" size={12} style={{ width: '100%' }}>
                  <div className="clue-detail-hero">
                    <div>
                      <Title level={5} style={{ margin: 0 }}>{detail.id}</Title>
                      <Text type="secondary">线索更新时间：{detail.update_time}</Text>
                    </div>
                    <Space wrap>
                      <Tag>{detail.level || '-'}</Tag>
                      <Button type="primary" onClick={openMessages}>查看所有上下文短信</Button>
                    </Space>
                  </div>

                  <div className="detail-feedback-block">
                    <div className="detail-feedback-main">
                      <Text strong>最新反馈</Text>
                      <div><Text>{detail.feedback || '-'}</Text></div>
                      <Text type="secondary">反馈时间：{detail.feedback_time || '-'}</Text>
                      <div><Text type="secondary">反馈人：{detail.feedback_username || '-'}</Text></div>
                    </div>
                    <div className="detail-feedback-side">
                      <Button size="middle" className="detail-feedback-history-btn" onClick={() => void openFeedbackHistory(detail.id)}>
                        查看全部历史反馈
                      </Button>
                    </div>
                  </div>

                  <div className="detail-summary-block">
                    <Text strong>AI总结</Text>
                    <Text>{detail.summary || '-'}</Text>
                  </div>

                  <div className="detail-remark-block">
                    <Text strong>额外信息</Text>
                    <Text>{detail.info || '-'}</Text>
                  </div>

                  <div className="detail-remark-block">
                    <Text strong>备注</Text>
                    <Text>{detail.remark || '-'}</Text>
                  </div>

                  <div className="detail-metric-row">
                    <div className="detail-metric-item">
                      <Text type="secondary">前科类型</Text>
                      <Text>{detail.qklx || '-'}</Text>
                    </div>
                    <div className="detail-metric-item">
                      <Text type="secondary">对方人员类型</Text>
                      <Text>{detail.label2 || '-'}</Text>
                    </div>
                    <div className="detail-metric-item">
                      <Text type="secondary">风险分数</Text>
                      <Text>{formatScore(detail.score)}</Text>
                    </div>
                  </div>

                  <Divider style={{ margin: '6px 0' }} />

                  <Descriptions size="small" column={2} bordered>
                    <Descriptions.Item label="类型">{detail.type || '-'}</Descriptions.Item>
                    <Descriptions.Item label="标记">{detail.mark_tag || '-'}</Descriptions.Item>
                    <Descriptions.Item label="号码1">{detail.msisdn_1}</Descriptions.Item>
                    <Descriptions.Item label="号码2">{detail.msisdn_2}</Descriptions.Item>
                    <Descriptions.Item label="记录数">{detail.cnt ?? '-'}</Descriptions.Item>
                    <Descriptions.Item label="近10天对话天数">{detail.cnt_dt ?? '-'}</Descriptions.Item>
                    <Descriptions.Item label="用户ID">{detail.user_id || '-'}</Descriptions.Item>
                    <Descriptions.Item label="用户名">{detail.user_name || '-'}</Descriptions.Item>
                    <Descriptions.Item label="状态">{detail.status || '-'}</Descriptions.Item>
                    <Descriptions.Item label="分配">{detail.distribute || '-'}</Descriptions.Item>
                  </Descriptions>
                </Space>
              )}
            </Card>
          </div>
        </div>

        <Modal title="所有上下文短信" open={messagesOpen} onCancel={() => setMessagesOpen(false)} footer={null} width={900}>
          <Table
            rowKey={(item) => `${item.sender}-${item.capture_time}-${item.message}`}
            dataSource={messagesData}
            pagination={{ pageSize: 8 }}
            rowClassName={(item) => (detail && item.sender === detail.msisdn_1 ? 'message-row-msisdn1' : '')}
            columns={[
              { title: '发送方', dataIndex: 'sender', width: 160 },
              { title: '发送时间', dataIndex: 'capture_time', width: 180 },
              { title: '发送内容', dataIndex: 'message' },
            ]}
          />
        </Modal>

        <Modal title={`反馈历史：${feedbackHistoryId}`} open={feedbackHistoryOpen} onCancel={() => setFeedbackHistoryOpen(false)} footer={null} width={860}>
          <Table
            rowKey={(item) => `${item.id}-${item.feedback_time}-${item.feedback}`}
            dataSource={feedbackHistoryData}
            pagination={{ pageSize: 6 }}
            columns={[
              { title: '反馈时间', dataIndex: 'feedback_time', width: 180 },
              { title: '反馈人', dataIndex: 'feedback_username', width: 140 },
              { title: '反馈内容', dataIndex: 'feedback' },
            ]}
          />
        </Modal>

        <Modal title="反馈填写" open={feedbackModalOpen} onCancel={() => setFeedbackModalOpen(false)} onOk={() => void saveFeedback()} okText="提交反馈" width={900}>
          <Space direction="vertical" style={{ width: '100%' }} size={12}>
            <Input.TextArea rows={4} value={feedbackInput} onChange={(e) => setFeedbackInput(e.target.value)} placeholder="请输入反馈内容" />
            <Input value={feedbackUser} onChange={(e) => setFeedbackUser(e.target.value)} placeholder="请填写反馈人（必填）" />
            <Divider style={{ margin: '6px 0' }} />
            <Text strong>历史反馈记录</Text>
            <Table
              size="small"
              rowKey={(item) => `${item.id}-${item.feedback_time}-${item.feedback}`}
              dataSource={feedbackHistoryInEditor}
              loading={feedbackHistoryLoading}
              pagination={{ pageSize: 4 }}
              columns={[
                { title: '反馈时间', dataIndex: 'feedback_time', width: 180 },
                { title: '反馈人', dataIndex: 'feedback_username', width: 120 },
                { title: '反馈内容', dataIndex: 'feedback' },
              ]}
            />
          </Space>
        </Modal>

        <Modal title={inputAction === 'remark' ? '备注' : '标记'} open={inputOpen} onCancel={() => setInputOpen(false)} onOk={() => void saveInput()} okText="保存">
          {inputAction === 'mark' ? (
            <Select value={inputValue} onChange={setInputValue} style={{ width: '100%' }} options={markOptions} />
          ) : (
            <Input.TextArea rows={4} value={inputValue} onChange={(e) => setInputValue(e.target.value)} placeholder="请输入内容" />
          )}
        </Modal>

        <Modal title={previewTitle} open={previewOpen} onCancel={() => setPreviewOpen(false)} onOk={() => setPreviewOpen(false)} okText="关闭" cancelButtonProps={{ style: { display: 'none' } }} width={860}>
          <pre style={{ margin: 0, whiteSpace: 'pre-wrap', lineHeight: 1.55 }}>{previewText}</pre>
        </Modal>
      </div>
    </ConfigProvider>
  )
}

export default CluesPage
