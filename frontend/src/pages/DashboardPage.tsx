import { Card, Col, Progress, Row, Space, Statistic, Typography } from 'antd'
import { CheckCircleTwoTone, LoadingOutlined } from '@ant-design/icons'
import ReactECharts from 'echarts-for-react'
import { useEffect, useMemo, useState } from 'react'
import { fetchOverview, fetchTrend, type DashboardOverview, type TrendPoint } from '../api/client'

const { Title, Text } = Typography

interface KpiState {
  high_risk_count: number
  new_clue_count: number
  pending_count: number
  feedback_count: number
}

const fallbackKpi: KpiState = {
  high_risk_count: 0,
  new_clue_count: 0,
  pending_count: 0,
  feedback_count: 0,
}

function DashboardPage() {
  const [kpi, setKpi] = useState<KpiState>(fallbackKpi)
  const [overview, setOverview] = useState<DashboardOverview | null>(null)
  const [trend, setTrend] = useState<TrendPoint[]>([])
  const [overviewLoading, setOverviewLoading] = useState(false)
  const [overviewLoadSucceeded, setOverviewLoadSucceeded] = useState(false)
  const [trendLoading, setTrendLoading] = useState(false)
  const [trendLoadSucceeded, setTrendLoadSucceeded] = useState(false)

  useEffect(() => {
    setOverviewLoading(true)
    setOverviewLoadSucceeded(false)
    fetchOverview()
      .then((data) => {
        setOverview(data)
        setKpi(data.kpi)
        setOverviewLoadSucceeded(true)
      })
      .catch(() => {
        setOverview(null)
        setKpi(fallbackKpi)
        setOverviewLoadSucceeded(false)
      })
      .finally(() => setOverviewLoading(false))

    setTrendLoading(true)
    setTrendLoadSucceeded(false)
    fetchTrend()
      .then((data) => {
        setTrend(data)
        setTrendLoadSucceeded(true)
      })
      .catch(() => {
        setTrend([])
        setTrendLoadSucceeded(false)
      })
      .finally(() => setTrendLoading(false))
  }, [])

  const trendOption = useMemo(() => ({
    tooltip: { trigger: 'axis' as const },
    legend: { top: 0 },
    grid: { left: 36, right: 16, top: 34, bottom: 28 },
    xAxis: { type: 'category' as const, data: trend.map((item) => item.date.slice(5)) },
    yAxis: { type: 'value' as const },
    series: [
      { name: '线索总量', type: 'line' as const, smooth: true, data: trend.map((item) => item.total), lineStyle: { width: 3, color: '#0f766e' }, areaStyle: { color: 'rgba(15,118,110,0.15)' } },
      { name: '高风险', type: 'line' as const, smooth: true, data: trend.map((item) => item.highRisk), lineStyle: { width: 2, color: '#b45309' } },
    ],
  }), [trend])

  const levelOption = useMemo(() => ({
    tooltip: { trigger: 'item' as const },
    series: [{ type: 'pie' as const, radius: ['45%', '70%'], itemStyle: { borderColor: '#fff8eb', borderWidth: 2 }, color: ['#b45309', '#0f766e', '#7c8a6a'], data: (overview?.level_distribution || []).map((item) => ({ value: item.value, name: item.name })) }],
  }), [overview])

  const totalForLoad = (overview?.kpi.pending_count || 0) + (overview?.kpi.feedback_count || 0)
  const riskLoading = Math.round((kpi.pending_count / Math.max(totalForLoad, 1)) * 100)

  const titleWithStatus = (title: string, loading: boolean, loaded: boolean) => (
    <Space size={8}>
      <span>{title}</span>
      {loading ? <LoadingOutlined spin style={{ color: '#1677ff' }} /> : loaded ? <CheckCircleTwoTone twoToneColor="#52c41a" /> : null}
    </Space>
  )

  const scoreDistOption = useMemo(() => {
    const buckets = overview?.score_distribution || []
    return {
      tooltip: { trigger: 'axis' as const },
      grid: { left: 34, right: 16, top: 26, bottom: 26 },
      xAxis: { type: 'category' as const, data: buckets.map((b) => b.label) },
      yAxis: { type: 'value' as const, minInterval: 1 },
      series: [{ type: 'bar' as const, data: buckets.map((b) => b.count), barWidth: '46%', itemStyle: { borderRadius: [8, 8, 0, 0], color: '#0ea5a3' } }],
    }
  }, [overview])

  const levelDistOption = useMemo(() => {
    const items = (overview?.level_distribution || []).map((it) => [it.name, it.value] as const).slice(0, 6)
    return {
      tooltip: { trigger: 'axis' as const },
      grid: { left: 16, right: 18, top: 16, bottom: 28, containLabel: true },
      xAxis: { type: 'value' as const, minInterval: 1 },
      yAxis: { type: 'category' as const, data: items.map((it) => it[0]) },
      series: [{ type: 'bar' as const, data: items.map((it) => it[1]), itemStyle: { borderRadius: [0, 8, 8, 0], color: '#0369a1' } }],
    }
  }, [overview])

  const minorOption = useMemo(() => {
    const minorCount = overview?.minor_distribution?.minor_count || 0
    const others = overview?.minor_distribution?.other_count || 0
    return {
      tooltip: { trigger: 'item' as const },
      color: ['#dc2626', '#94a3b8'],
      series: [{ type: 'pie' as const, radius: ['48%', '74%'], label: { formatter: '{b}\n{c}条' }, data: [{ name: '涉未成年', value: minorCount }, { name: '其他线索', value: others }] }],
    }
  }, [overview])

  return (
    <div className="prism-page">
      <Card className="hero-card" bordered={false}>
        <Space direction="vertical" size={4}>
          <Text className="hero-eyebrow">棱镜系统 设计方向</Text>
          <Title level={3} style={{ margin: 0 }}>先聚焦风险，再进入处置</Title>
          <Text type="secondary">信息层级：全局态势 - 待办对象 - 单案深挖，减少跳转和认知负担。业务日：{overview?.biz_date || '-'}</Text>
        </Space>
      </Card>

      <Row gutter={[16, 16]}>
        <Col span={6}><Card className="metric-card"><Statistic title="高风险对象" value={kpi.high_risk_count} /></Card></Col>
        <Col span={6}><Card className="metric-card"><Statistic title="新增线索（当日）" value={kpi.new_clue_count} /></Card></Col>
        <Col span={6}><Card className="metric-card"><Statistic title="待核查" value={kpi.pending_count} /></Card></Col>
        <Col span={6}><Card className="metric-card"><Statistic title="已反馈" value={kpi.feedback_count} /></Card></Col>
      </Row>

      <Row gutter={[16, 16]} style={{ marginTop: 2 }}>
        <Col span={14}><Card title={titleWithStatus('趋势跟踪', trendLoading, trendLoadSucceeded)} className="panel-card"><ReactECharts option={trendOption} style={{ height: 280 }} /></Card></Col>
        <Col span={10}>
          <Card title={titleWithStatus('风险类型分布（业务日）', overviewLoading, overviewLoadSucceeded)} className="panel-card">
            <ReactECharts option={levelOption} style={{ height: 280 }} />
            <div style={{ marginTop: 8 }}>
              <Text type="secondary">核查负载</Text>
              <Progress percent={riskLoading} strokeColor="#0f766e" showInfo />
            </div>
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]} style={{ marginTop: 2 }}>
        <Col span={8}><Card title={titleWithStatus('评分分布（业务日）', overviewLoading, overviewLoadSucceeded)} className="panel-card"><ReactECharts option={scoreDistOption} style={{ height: 250 }} /></Card></Col>
        <Col span={8}><Card title={titleWithStatus('线索等级分布（业务日）', overviewLoading, overviewLoadSucceeded)} className="panel-card"><ReactECharts option={levelDistOption} style={{ height: 250 }} /></Card></Col>
        <Col span={8}><Card title={titleWithStatus('涉未成年占比（业务日）', overviewLoading, overviewLoadSucceeded)} className="panel-card"><ReactECharts option={minorOption} style={{ height: 250 }} /></Card></Col>
      </Row>
    </div>
  )
}

export default DashboardPage
