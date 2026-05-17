import axios from 'axios'
import { ElMessage } from 'element-plus'

const request = axios.create({
  baseURL: '/api',
  timeout: 10000
})

request.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

request.interceptors.response.use(
  response => {
    if (response.data.code === 200) return response.data.data
    ElMessage.error(response.data.message || '请求失败')
    return Promise.reject(new Error(response.data.message))
  },
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.hash = '#/login'
    }
    ElMessage.error('网络错误')
    return Promise.reject(error)
  }
)

// User
export const userLogin = (data) => request.post('/user/login', data)
export const userRegister = (data) => request.post('/user/register', data)
export const getUserProfile = () => request.get('/user/profile')
export const updateUserProfile = (data) => request.put('/user/profile', data)

// Goals
export const getGoalList = (level) => request.get('/goal/list', { params: { level } })
export const getGoalPage = (page, size) => request.get('/goal/page', { params: { page, size } })
export const saveGoal = (data) => request.post('/goal', data)
export const updateGoal = (data) => request.put('/goal', data)
export const updateGoalProgress = (data) => request.put('/goal/progress', data)
export const deleteGoal = (id) => request.delete(`/goal/${id}`)

// Tasks
export const getTaskList = (date) => request.get('/task/list', { params: { date } })
export const getTaskQuadrant = (level) => request.get('/task/quadrant', { params: { level } })
export const saveTask = (data) => request.post('/task', data)
export const toggleTask = (id) => request.put(`/task/toggle/${id}`)
export const deleteTask = (id) => request.delete(`/task/${id}`)

// Daily Records
export const getRecordPage = (page, size, type) => request.get('/record/page', { params: { page, size, type } })
export const getRecordStats = (start, end) => request.get('/record/stats', { params: { start, end } })
export const saveRecord = (data) => request.post('/record', data)
export const updateRecord = (data) => request.put('/record', data)
export const deleteRecord = (id) => request.delete(`/record/${id}`)

// Behavior
export const getBehaviorStats = (start, end) => request.get('/behavior/stats', { params: { start, end } })
export const getBehaviorList = (type) => request.get('/behavior/list', { params: { type } })
export const saveBehavior = (data) => request.post('/behavior', data)

// Finance
export const getFinancePage = (page, size) => request.get('/finance/page', { params: { page, size } })
export const getFinanceWeekStats = () => request.get('/finance/week-stats')
export const saveFinance = (data) => request.post('/finance', data)
export const updateFinance = (data) => request.put('/finance', data)

// Study
export const getStudyPage = (page, size, trackType) => request.get('/study/page', { params: { page, size, trackType } })
export const getStudyStats = (start, end) => request.get('/study/stats', { params: { start, end } })
export const saveStudy = (data) => request.post('/study', data)
export const updateStudy = (data) => request.put('/study', data)

// Sideline
export const getSidelinePage = (page, size) => request.get('/sideline/page', { params: { page, size } })
export const getSidelineProgress = () => request.get('/sideline/progress')
export const saveSideline = (data) => request.post('/sideline', data)
export const updateSideline = (data) => request.put('/sideline', data)

// Empty Mood
export const getEmptyPage = (page, size) => request.get('/empty/page', { params: { page, size } })
export const getEmptyTrend = (start, end) => request.get('/empty/trend', { params: { start, end } })
export const saveEmpty = (data) => request.post('/empty', data)

// Book Reading
export const getBookPage = (page, size, bookType) => request.get('/book/page', { params: { page, size, bookType } })
export const getBookStats = () => request.get('/book/stats')
export const saveBook = (data) => request.post('/book', data)
export const updateBook = (data) => request.put('/book', data)

// Leisure
export const getLeisurePage = (page, size) => request.get('/leisure/page', { params: { page, size } })
export const getLeisureTrend = (start, end) => request.get('/leisure/trend', { params: { start, end } })
export const saveLeisure = (data) => request.post('/leisure', data)

// Elite Habits & Plans
export const getEliteHabits = (category) => request.get('/elite-habit/list', { params: { category } })
export const getDailyPlan = (date) => request.get(`/plan/date/${date}`)
export const generateTodayPlan = () => request.post('/plan/generate')
export const savePlan = (data) => request.post('/plan', data)

// Compare Check
export const getDailyCheck = (date) => request.get(`/check/date/${date}`)
export const getWeekCheckStats = () => request.get('/check/week-stats')
export const saveCheck = (data) => request.post('/check', data)

// AI Report
export const generateReport = (cycleType) => request.post('/report/generate', null, { params: { cycleType } })
export const getReportPage = (page, size) => request.get('/report/page', { params: { page, size } })
export const deleteReport = (id) => request.delete(`/report/${id}`)

// Data Sync
export const syncUpload = (data) => request.post('/sync/upload', data)
export const syncExport = (start, end) => request.get('/sync/export', { params: { start, end } })
