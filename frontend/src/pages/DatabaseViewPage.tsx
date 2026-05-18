import { Button, Card, Input, Modal, Select, Space, Table, Typography, message } from 'antd'
import { type MouseEvent as ReactMouseEvent, useEffect, useMemo, useRef, useState } from 'react'
import { fetchDatabaseTableRows, fetchDatabaseTables, importDistributeToWorkflow, importFeedbackToHistory, resolveApiErrorDetails, type DatabaseTableRows } from '../api/client'

const { Title, Text } = Typography

function getDefaultColumnWidth(name: string, primaryKeys: string[]) {
  const primaryKeySet = new Set((primaryKeys || []).map((x) => x.toLowerCase()))
  if (primaryKeySet.has(name.toLowerCase())) {
    return 108
  }
  return Math.min(180, Math.max(96, name.length * 14 + 30))
}

function TruncatableCell({
  fieldName,
  text,
  onPreview,
}: {
  fieldName: string
  text: string
  onPreview: (fieldName: string, text: string) => void
}) {
  const textRef = useRef<HTMLSpanElement | null>(null)
  const [isTruncated, setIsTruncated] = useState(false)

  useEffect(() => {
    const el = textRef.current
    if (!el) return

    const checkTruncation = () => {
      setIsTruncated(el.scrollWidth > el.clientWidth || el.scrollHeight > el.clientHeight)
    }

    checkTruncation()

    let observer: ResizeObserver | null = null
    if (typeof ResizeObserver !== 'undefined') {
      observer = new ResizeObserver(() => checkTruncation())
      observer.observe(el)
    }

    window.addEventListener('resize', checkTruncation)

    return () => {
      observer?.disconnect()
      window.removeEventListener('resize', checkTruncation)
    }
  }, [text])

  return (
    <span
      ref={textRef}
      className={`cell-fade-ellipsis db-cell-trunc${isTruncated ? ' is-truncated' : ''}`}
      title={isTruncated ? '点击查看并复制' : text}
      onClick={() => {
        if (!isTruncated) return
        onPreview(fieldName, text)
      }}
    >
      {text}
    </span>
  )
}

function DatabaseViewPage() {
  const [databaseKey, setDatabaseKey] = useState<'sdata' | 'wxzdb'>('wxzdb')
  const [tables, setTables] = useState<string[]>([])
  const [selectedTable, setSelectedTable] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [importing, setImporting] = useState(false)
  const [data, setData] = useState<DatabaseTableRows | null>(null)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [previewOpen, setPreviewOpen] = useState(false)
  const [previewText, setPreviewText] = useState('')
  const [previewTitle, setPreviewTitle] = useState('字段内容')
  const [filterField, setFilterField] = useState('')
  const [filterValue, setFilterValue] = useState('')
  const [tableColumns, setTableColumns] = useState<string[]>([])
  const [columnWidths, setColumnWidths] = useState<Record<string, number>>({})
  const [resizingCol, setResizingCol] = useState<string | null>(null)
  const resizeRef = useRef<{ key: string; startX: number; startWidth: number } | null>(null)

  const columnWidthStorageKey = useMemo(
    () => `prism:db-table-column-widths:${databaseKey}:${selectedTable || '__none__'}`,
    [databaseKey, selectedTable],
  )

  const resolveApiErrorMessage = (error: unknown, fallback: string) => {
    const details = resolveApiErrorDetails(error, fallback)
    const trace = details.traceId ? ' (trace_id=' + details.traceId + ')' : ''
    return fallback + ': ' + details.message + trace
  }

  useEffect(() => {
    fetchDatabaseTables(databaseKey)
      .then((list) => {
        setTables(list)
        setSelectedTable('')
        setTableColumns([])
        setFilterField('')
        setFilterValue('')
        setPage(1)
      })
      .catch(() => {
        setTables([])
        message.error('数据库表列表加载失败')
      })
  }, [databaseKey])

  useEffect(() => {
    if (!selectedTable) {
      setTableColumns([])
      setFilterField('')
      return
    }
    fetchDatabaseTableRows(databaseKey, selectedTable, 1, 1)
      .then((result) => {
        setTableColumns(result.columns || [])
        if (filterField && !(result.columns || []).includes(filterField)) {
          setFilterField('')
        }
      })
      .catch(() => {
        setTableColumns([])
      })
  }, [databaseKey, selectedTable])

  useEffect(() => {
    if (!selectedTable) {
      setColumnWidths({})
      return
    }
    const raw = localStorage.getItem(columnWidthStorageKey)
    if (!raw) {
      setColumnWidths({})
      return
    }
    try {
      const parsed = JSON.parse(raw) as Record<string, unknown>
      const next: Record<string, number> = {}
      Object.entries(parsed).forEach(([key, val]) => {
        const n = Number(val)
        if (Number.isFinite(n) && n > 40) {
          next[key] = n
        }
      })
      setColumnWidths(next)
    } catch {
      setColumnWidths({})
    }
  }, [columnWidthStorageKey, selectedTable])

  useEffect(() => {
    if (!selectedTable) return
    localStorage.setItem(columnWidthStorageKey, JSON.stringify(columnWidths))
  }, [columnWidthStorageKey, columnWidths, selectedTable])

  useEffect(() => {
    if (!resizingCol) return
    const onMove = (event: MouseEvent) => {
      const current = resizeRef.current
      if (!current) return
      const delta = event.clientX - current.startX
      const nextWidth = Math.max(80, Math.round(current.startWidth + delta))
      setColumnWidths((prev) => ({ ...prev, [current.key]: nextWidth }))
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

  useEffect(() => {
    if (!data?.columns?.length) return
    setColumnWidths((prev) => {
      const next = { ...prev }
      let changed = false
      data.columns.forEach((name) => {
        const current = Number(next[name])
        if (!Number.isFinite(current) || current < 40) {
          next[name] = getDefaultColumnWidth(name, data.primary_keys || [])
          changed = true
        }
      })
      return changed ? next : prev
    })
  }, [data])

  const loadRows = async (nextPage = page, nextPageSize = pageSize, nextField = filterField, nextValue = filterValue) => {
    if (!selectedTable) {
      message.warning('请先选择数据表后查看')
      return
    }
    setLoading(true)
    try {
      const result = await fetchDatabaseTableRows(databaseKey, selectedTable, nextPage, nextPageSize, nextField, nextValue)
      const primaryKeys = result.primary_keys || []
      const rowsWithKey = result.rows.map((row, index) => {
        const composite = primaryKeys
          .map((key) => String(row[key] ?? ''))
          .filter((v) => v.length > 0)
          .join('||')
        const fallback = `${result.table}-${nextPage}-${index}`
        return {
          ...row,
          __row_key: composite || fallback,
        }
      })
      setData({ ...result, rows: rowsWithKey })
      setPage(nextPage)
      setPageSize(nextPageSize)
    } catch {
      message.error('表数据加载失败')
      setData(null)
    } finally {
      setLoading(false)
    }
  }

  const handleImportFeedback = async () => {
    setImporting(true)
    try {
      const result = await importFeedbackToHistory()
      const failedExamples = (result.failed_examples || []).filter((item) => !!item)
      const extra = failedExamples.length
        ? `\n\n失败原因示例（最多10条）:\n- ${failedExamples.join('\n- ')}`
        : ''
      Modal.success({
        title: '导入完成',
        content: `已完成 ${result.source_table} -> ${result.target_table} 导入。成功 ${result.imported}，跳过 ${result.skipped}，失败 ${result.failed}。${extra}`,
      })
    } catch (error) {
      message.error(resolveApiErrorMessage(error, '导入失败'))
    } finally {
      setImporting(false)
    }
  }

  const handleImportDistribute = async () => {
    setImporting(true)
    try {
      const result = await importDistributeToWorkflow()
      Modal.success({
        title: '导入完成',
        content: `已完成 ${result.source_table} -> ${result.target_table} 导入。写入/更新 ${result.insert_or_update}，分配同步 ${result.updated_distribute}，等级同步 ${result.updated_level}。`,
      })
    } catch (error) {
      message.error(resolveApiErrorMessage(error, '导入失败'))
    } finally {
      setImporting(false)
    }
  }

  const handleClearClientCache = () => {
    try {
      localStorage.clear()
      sessionStorage.clear()
      const cookies = document.cookie ? document.cookie.split(';') : []
      cookies.forEach((entry) => {
        const name = entry.split('=')[0]?.trim()
        if (!name) return
        document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`
        if (window.location.hostname) {
          document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; domain=${window.location.hostname}`
          document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; domain=.${window.location.hostname}`
        }
      })
      message.success('已清空会话 Cookie、本地缓存和会话存储')
    } catch {
      message.error('清空缓存失败，请稍后重试')
    }
  }

  const columns = useMemo(() => {
    if (!data) return []
    const startResizeColumn = (event: ReactMouseEvent<HTMLElement>, key: string, width: number) => {
      event.preventDefault()
      event.stopPropagation()
      resizeRef.current = { key, startX: event.clientX, startWidth: width }
      setResizingCol(key)
    }

    const buildHeaderCellProps = (key: string, width: number) => ({
      className: `db-resizable-header${resizingCol === key ? ' is-resizing' : ''}`,
      onMouseDown: (event: ReactMouseEvent<HTMLElement>) => {
        const th = event.currentTarget as HTMLElement
        const rect = th.getBoundingClientRect()
        const distanceToRight = rect.right - event.clientX
        if (distanceToRight > 10) return
        startResizeColumn(event, key, width)
      },
    })

    return data.columns.map((name) => ({
      title: name,
      dataIndex: name,
      key: name,
      ellipsis: true,
      width: columnWidths[name] || getDefaultColumnWidth(name, data.primary_keys || []),
      onHeaderCell: () => buildHeaderCellProps(name, columnWidths[name] || getDefaultColumnWidth(name, data.primary_keys || [])),
      render: (value: unknown) => {
        if (value == null) return '-'
        const text = typeof value === 'object' ? JSON.stringify(value) : String(value)
        if (!text) return '-'
        return (
          <TruncatableCell
            fieldName={name}
            text={text}
            onPreview={(field, fullText) => {
              setPreviewTitle(`字段：${field}`)
              setPreviewText(fullText)
              setPreviewOpen(true)
              void navigator.clipboard.writeText(fullText).then(() => {
                message.success('已复制字段内容')
              }).catch(() => {
                message.warning('复制失败，请手动复制')
              })
            }}
          />
        )
      },
    }))
  }, [columnWidths, data, resizingCol])

  const tableScrollX = useMemo(() => {
    if (!data) return 0
    return data.columns.reduce((sum, name) => sum + (columnWidths[name] || getDefaultColumnWidth(name, data.primary_keys || [])), 0)
  }, [columnWidths, data])

  const dbLabel = data?.db || ''

  return (
    <div className="prism-page db-manage-page">
      <Title level={4}>数据库管理</Title>
      <Card className="panel-card db-manage-toolbar" style={{ marginBottom: 14 }}>
        <Space wrap>
          <Select
            value={databaseKey}
            style={{ width: 180 }}
            options={[
              { label: '库：wxzdb', value: 'wxzdb' },
              { label: '库：sdata', value: 'sdata' },
            ]}
            onChange={(v) => setDatabaseKey(v as 'sdata' | 'wxzdb')}
          />
          <Select
            showSearch
            placeholder="选择数据表"
            value={selectedTable || undefined}
            style={{ width: 320 }}
            options={tables.map((name) => ({ label: name, value: name }))}
            onChange={(v) => {
              setSelectedTable(v)
              setPage(1)
              setFilterField('')
              setFilterValue('')
            }}
          />
          <Select
            placeholder="筛选字段"
            value={filterField || undefined}
            style={{ width: 180 }}
            options={tableColumns.map((name) => ({ label: name, value: name }))}
            onChange={(v) => setFilterField(v)}
          />
          <Input
            value={filterValue}
            onChange={(e) => setFilterValue(e.target.value)}
            onPressEnter={() => { void loadRows(1, pageSize, filterField, filterValue) }}
            placeholder="输入查找值（模糊匹配）"
            style={{ width: 240 }}
          />
          <Button type="primary" onClick={() => { void loadRows() }} loading={loading}>查看数据</Button>
          <Button
            onClick={() => {
              setFilterField('')
              setFilterValue('')
              void loadRows(1, pageSize, '', '')
            }}
            disabled={!filterField && !filterValue}
          >
            清空筛选
          </Button>
          <Button className="db-import-btn" onClick={handleImportFeedback} loading={importing}>一键导入反馈</Button>
          <Button className="db-import-btn" onClick={handleImportDistribute} loading={importing}>一键导入线索分配和等级</Button>
          <Button onClick={handleClearClientCache}>清空缓存</Button>
        </Space>
        <div style={{ marginTop: 10 }}>
          <Text type="secondary">当前库共 {tables.length} 个数据表，使用分页浏览表数据。</Text>
        </div>
      </Card>

      <Card className="panel-card db-manage-table-card" title={data ? `库：${dbLabel} | 表：${data.table}` : '表数据预览'}>
        <Table
          className="db-resizable-table"
          rowKey="__row_key"
          dataSource={data?.rows || []}
          columns={columns}
          scroll={{ x: tableScrollX }}
          tableLayout="fixed"
          pagination={{
            current: page,
            pageSize,
            total: data?.total || 0,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50', '100'],
            onChange: (p, ps) => {
              void loadRows(p, ps, filterField, filterValue)
            },
          }}
          locale={{ emptyText: selectedTable ? '暂无数据' : '请选择数据表后查看' }}
        />
      </Card>

      <Modal
        title={previewTitle}
        open={previewOpen}
        onCancel={() => setPreviewOpen(false)}
        onOk={() => setPreviewOpen(false)}
        okText="关闭"
        cancelButtonProps={{ style: { display: 'none' } }}
        width={860}
      >
        <pre style={{ margin: 0, whiteSpace: 'pre-wrap', lineHeight: 1.55 }}>{previewText}</pre>
      </Modal>
    </div>
  )
}

export default DatabaseViewPage
