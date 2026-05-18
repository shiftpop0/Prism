import axios from 'axios'

export interface ApiResponse<T> {
  code: string
  message: string
  data: T
  trace_id: string
}

export interface DashboardOverview {
  biz_date?: string
  kpi: {
    high_risk_count: number
    new_clue_count: number
    pending_count: number
    feedback_count: number
  }
  score_distribution?: Array<{ label: string; min: number; max: number; count: number }>
  level_distribution?: Array<{ name: string; value: number }>
  minor_distribution?: { minor_count: number; other_count: number }
}

export interface TrendPoint {
  date: string
  total: number
  highRisk: number
}

export interface TypeDistItem {
  type: string
  value: number
}

export interface SummaryCase {
  id: string
  type: string
  qklx?: string
  level?: string
  message?: string
  summary?: string
  region?: string
  info?: string
  assign_to?: string
  msisdn_1: string
  msisdn_2: string
  score: number
  update_time: string
  data_date?: string
  status: string
  feedback: string
  feedback_time?: string
  feedback_username?: string
  remark: string
  mark_tag: string
  distribute: string
}

export interface CaseDetail {
  id: string
  type: string
  level?: string
  msisdn_1: string
  msisdn_2: string
  cnt: number
  cnt_dt: number
  message?: string
  summary: string
  region?: string
  info?: string
  assign_to?: string
  score: number
  qklx: string
  label2: string
  user_id: string
  user_name: string
  status: string
  feedback: string
  feedback_time?: string
  feedback_username?: string
  remark: string
  mark_tag: string
  distribute: string
  update_time: string
  data_date?: string
}

export interface FeedbackHistoryItem {
  id: string
  feedback: string
  feedback_time: string
  feedback_username?: string
}

export interface MessageCase {
  sender: string
  capture_time: string
  message: string
}

export interface DialogueData {
  answer: string
  citations: Array<{
    evidence_id: string
    title: string
    source: string
  }>
  safety_flags: string[]
}

export interface DialogueAgentSpec {
  title: string
  description: string
  command: string
  script_path: string
  script: string
  quick_prompts?: string[]
}

export interface SummaryCasesPage {
  total: number
  page: number
  page_size: number
  list: SummaryCase[]
}

export interface ClueFilterOptions {
  status_options: string[]
  distribute_options: string[]
  region_options: string[]
}

export interface ApiErrorDetails {
  status?: number
  code?: string
  message: string
  traceId?: string
}

export interface DialogueSnapshotData {
  scope: 'single' | 'all' | 'day'
  focus_id?: string
  date: string
  title: string
  source: string
  snapshot: string
  system_prompt: string
}

export interface DatabaseTableRows {
  db: string
  table: string
  columns: string[]
  primary_keys?: string[]
  rows: Array<Record<string, unknown>>
  page: number
  page_size: number
  total: number
}

export interface ImportFeedbackResult {
  source_table: string
  target_table: string
  imported: number
  skipped: number
  failed: number
  failed_examples?: string[]
}

export interface ImportDistributeResult {
  source_table: string
  target_table: string
  insert_or_update: number
  updated_distribute: number
  updated_level: number
}

export interface InitWorkflowStateResult {
  target_table: string
  inserted: number
  updated: number
}

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 10000,
})

export function resolveApiErrorDetails(error: unknown, fallbackMessage: string): ApiErrorDetails {
  if (axios.isAxiosError(error)) {
    const payload = error.response?.data as Partial<ApiResponse<unknown>> | undefined
    return {
      status: error.response?.status,
      code: typeof payload?.code === 'string' ? payload.code : undefined,
      message:
        typeof payload?.message === 'string' && payload.message.trim()
          ? payload.message
          : fallbackMessage,
      traceId: typeof payload?.trace_id === 'string' ? payload.trace_id : undefined,
    }
  }
  if (error instanceof Error && error.message.trim()) {
    return { message: error.message }
  }
  return { message: fallbackMessage }
}

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const details = resolveApiErrorDetails(error, 'request failed')
    if (typeof console !== 'undefined') {
      // Keep full context for debugging in browser devtools.
      console.error('[API_ERROR]', {
        message: details.message,
        code: details.code,
        traceId: details.traceId,
        status: details.status,
        error,
      })
    }
    return Promise.reject(error)
  },
)

export async function fetchOverview(): Promise<DashboardOverview> {
  const { data } = await api.get<ApiResponse<DashboardOverview>>('/dashboard/overview')
  return data.data
}

export async function fetchTrend(): Promise<TrendPoint[]> {
  const { data } = await api.get<ApiResponse<Array<{ date: string; total: number; high_risk: number }>>>('/dashboard/trend')
  return data.data.map((item) => ({ date: item.date, total: item.total, highRisk: item.high_risk }))
}

export async function fetchTypeDistribution(): Promise<TypeDistItem[]> {
  const { data } = await api.get<ApiResponse<TypeDistItem[]>>('/dashboard/type-distribution')
  return data.data
}

export interface FetchSummaryCasesParams {
  keyword?: string
  page?: number
  pageSize?: number
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
  status?: string
  markTag?: string
  distribute?: string
  region?: string
  scoreMin?: number
  scoreMax?: number
  dataDateFrom?: string
  dataDateTo?: string
}

export async function fetchSummaryCases(params?: FetchSummaryCasesParams): Promise<SummaryCasesPage> {
  const { data } = await api.get<ApiResponse<SummaryCasesPage>>('/clues', {
    params: {
      keyword: params?.keyword || undefined,
      page: params?.page || 1,
      page_size: params?.pageSize || 20,
      sort_by: params?.sortBy || undefined,
      sort_order: params?.sortOrder || undefined,
      status: params?.status || undefined,
      mark_tag: params?.markTag || undefined,
      distribute: params?.distribute || undefined,
      region: params?.region || undefined,
      score_min: params?.scoreMin ?? undefined,
      score_max: params?.scoreMax ?? undefined,
      data_date_from: params?.dataDateFrom || undefined,
      data_date_to: params?.dataDateTo || undefined,
    },
    timeout: 60000,
  })
  return data.data
}

export async function fetchClueFilterOptions(): Promise<ClueFilterOptions> {
  const { data } = await api.get<ApiResponse<ClueFilterOptions>>('/clues/filter-options', {
    timeout: 30000,
  })
  return data.data
}

export async function fetchClueDetail(id: string): Promise<CaseDetail> {
  const { data } = await api.get<ApiResponse<CaseDetail>>(`/clues/${encodeURIComponent(id)}/detail`)
  return data.data
}

export async function fetchCaseMessages(id: string): Promise<MessageCase[]> {
  const { data } = await api.get<ApiResponse<MessageCase[]>>(`/clues/${encodeURIComponent(id)}/messages`)
  return data.data
}

export async function fetchClueFeedbacks(id: string): Promise<FeedbackHistoryItem[]> {
  const { data } = await api.get<ApiResponse<FeedbackHistoryItem[]>>(`/clues/${encodeURIComponent(id)}/feedbacks`)
  return data.data
}

export async function updateClueAction(id: string, action: 'feedback' | 'remark' | 'mark', value: string, feedbackUser?: string) {
  const { data } = await api.post<ApiResponse<{ id: string }>>(`/clues/${encodeURIComponent(id)}/action`, {
    action,
    value,
    feedback_user: feedbackUser || '',
  })
  return data.data
}

export async function sendDialogueMessage(content: string, focusId?: string): Promise<DialogueData> {
  const { data } = await api.post<ApiResponse<DialogueData>>('/dialogue/sessions/s_001/messages', {
    role: 'user',
    content,
    focus_id: focusId || '',
  }, {
    timeout: 60000,
  })
  return data.data
}

export interface DialogueRequestOptions {
  focusId?: string
  scope?: 'single' | 'all' | 'day'
  date?: string
}

export async function sendDialogueMessageV2(content: string, options?: DialogueRequestOptions): Promise<DialogueData> {
  const { data } = await api.post<ApiResponse<DialogueData>>('/dialogue/sessions/s_001/messages', {
    role: 'user',
    content,
    focus_id: options?.focusId || '',
    scope: options?.scope || 'single',
    date: options?.date || '',
  }, {
    timeout: 60000,
  })
  return data.data
}

export async function fetchDialogueAgentSpec(): Promise<DialogueAgentSpec> {
  const { data } = await api.get<ApiResponse<DialogueAgentSpec>>('/dialogue/agent-spec')
  return data.data
}

export async function fetchDialogueSnapshot(options?: DialogueRequestOptions): Promise<DialogueSnapshotData> {
  const { data } = await api.get<ApiResponse<DialogueSnapshotData>>('/dialogue/snapshot', {
    params: {
      focus_id: options?.focusId || '',
      scope: options?.scope || 'single',
      date: options?.date || '',
    },
  })
  return data.data
}

export async function fetchDatabaseTables(db: 'sdata' | 'wxzdb'): Promise<string[]> {
  const { data } = await api.get<ApiResponse<{ db: string; tables: string[] }>>('/db/tables', {
    params: { db },
  })
  return data.data.tables
}

export async function fetchDatabaseTableRows(
  db: 'sdata' | 'wxzdb',
  tableName: string,
  page = 1,
  pageSize = 20,
  filterField = '',
  filterValue = '',
): Promise<DatabaseTableRows> {
  const { data } = await api.get<ApiResponse<DatabaseTableRows>>(`/db/tables/${encodeURIComponent(tableName)}`, {
    params: {
      db,
      page,
      page_size: pageSize,
      filter_field: filterField || undefined,
      filter_value: filterValue || undefined,
    },
  })
  return data.data
}

export async function importFeedbackToHistory(): Promise<ImportFeedbackResult> {
  const { data } = await api.post<ApiResponse<ImportFeedbackResult>>('/db/import-feedback-to-history')
  return data.data
}

export async function importDistributeToWorkflow(): Promise<ImportDistributeResult> {
  const { data } = await api.post<ApiResponse<ImportDistributeResult>>('/db/import-distribute-to-workflow')
  return data.data
}

export async function initWorkflowState(): Promise<InitWorkflowStateResult> {
  const { data } = await api.post<ApiResponse<InitWorkflowStateResult>>('/db/init-workflow-state')
  return data.data
}
