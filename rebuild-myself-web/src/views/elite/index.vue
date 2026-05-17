<template>
  <div class="page-container">
    <div class="page-header">
      <h2>精英对标</h2>
      <el-date-picker
        v-model="planDate"
        type="date"
        placeholder="选择日期"
        value-format="YYYY-MM-DD"
        style="width: 160px;"
        @change="fetchPlanData"
      />
    </div>

    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>今日模型计划</span>
          <el-button type="primary" size="small" :loading="generating" @click="handleGeneratePlan">
            生成今日计划
          </el-button>
        </div>
      </template>
      <el-table :data="planList" stripe v-loading="planLoading" style="width: 100%">
        <el-table-column prop="timePeriod" label="时间段" width="120" />
        <el-table-column prop="content" label="计划内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="planTypeTag(row.type)" size="small">{{ row.type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="difficulty" label="难度" width="100" align="center">
          <template #default="{ row }">
            <el-rate v-model="row.difficulty" disabled :max="5" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80" fixed="right">
          <template #default="{ row }">
            <el-button text size="small" @click="openPlanDialog(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card>
      <template #header><span>每日自查</span></template>
      <div v-if="dailyCheck">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="日期">{{ dailyCheck.date }}</el-descriptions-item>
          <el-descriptions-item label="进度评分">
            <el-rate v-model="dailyCheck.progressScore" disabled :max="10" />
          </el-descriptions-item>
          <el-descriptions-item label="偏差描述" :span="2">{{ dailyCheck.deviation || '无' }}</el-descriptions-item>
          <el-descriptions-item label="逃避理由" :span="2">{{ dailyCheck.escapeReason || '无' }}</el-descriptions-item>
        </el-descriptions>
        <el-button type="primary" size="small" style="margin-top: 12px;" @click="openCheckDialog">
          {{ dailyCheck.id ? '编辑自查' : '新增自查' }}
        </el-button>
      </div>
      <div v-else style="color: #999; padding: 20px 0; text-align: center;">
        暂无自查数据
        <el-button type="primary" size="small" style="margin-left: 12px;" @click="openCheckDialog">新增自查</el-button>
      </div>
    </el-card>

    <el-card>
      <template #header><span>精英习惯库</span></template>
      <el-tabs v-model="habitCategory" @tab-change="fetchHabits">
        <el-tab-pane label="晨间" name="morning" />
        <el-tab-pane label="日间" name="daytime" />
        <el-tab-pane label="下班后" name="afterwork" />
        <el-tab-pane label="睡前" name="bedtime" />
      </el-tabs>
      <div v-if="habits.length === 0" style="color: #999; padding: 20px 0; text-align: center;">暂无习惯数据</div>
      <el-row :gutter="16">
        <el-col :span="12" v-for="habit in habits" :key="habit.id" style="margin-bottom: 12px;">
          <el-card shadow="hover" style="margin: 0;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <span style="font-size: 14px; font-weight: 500;">{{ habit.name }}</span>
              <el-tag :type="intensityTag(habit.intensity)" size="small" effect="dark">
                {{ intensityLabel(habit.intensity) }}
              </el-tag>
            </div>
            <p style="font-size: 12px; color: #909399; margin: 8px 0 0 0;">{{ habit.description }}</p>
          </el-card>
        </el-col>
      </el-row>
    </el-card>

    <el-card>
      <template #header><span>周对比统计</span></template>
      <el-table :data="weekStats" stripe v-loading="weekLoading" style="width: 100%">
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="score" label="评分" width="120" align="center">
          <template #default="{ row }">
            <el-rate v-model="row.score" disabled :max="10" />
          </template>
        </el-table-column>
        <el-table-column prop="deviation" label="偏差描述" min-width="200" show-overflow-tooltip />
      </el-table>
    </el-card>

    <el-dialog v-model="planDialogVisible" title="编辑计划" width="500px">
      <el-form :model="planForm" label-position="top">
        <el-form-item label="时间段">
          <el-select v-model="planForm.timePeriod" style="width: 100%;">
            <el-option label="早晨" value="早晨" />
            <el-option label="上午" value="上午" />
            <el-option label="中午" value="中午" />
            <el-option label="下午" value="下午" />
            <el-option label="晚上" value="晚上" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划内容">
          <el-input v-model="planForm.content" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="类型">
          <el-input v-model="planForm.type" placeholder="如：学习、工作、健康" />
        </el-form-item>
        <el-form-item label="难度">
          <el-rate v-model="planForm.difficulty" :max="5" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="planDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingPlan" @click="handleSavePlan">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="checkDialogVisible" :title="dailyCheck?.id ? '编辑自查' : '新增自查'" width="500px">
      <el-form :model="checkForm" label-position="top">
        <el-form-item label="偏差描述">
          <el-input v-model="checkForm.deviation" type="textarea" :rows="3" placeholder="今天与计划之间的偏差" />
        </el-form-item>
        <el-form-item label="逃避理由">
          <el-input v-model="checkForm.escapeReason" type="textarea" :rows="2" placeholder="如果有逃避行为，写下原因" />
        </el-form-item>
        <el-form-item label="进度评分">
          <el-slider v-model="checkForm.progressScore" :min="0" :max="10" :step="1" show-input />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="checkDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingCheck" @click="handleSaveCheck">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import {
  getDailyPlan, generateTodayPlan, savePlan,
  getEliteHabits,
  getDailyCheck, getWeekCheckStats, saveCheck
} from '@/api'

const planDate = ref(new Date().toISOString().slice(0, 10))
const generating = ref(false)
const planLoading = ref(false)
const planList = ref([])
const habitCategory = ref('morning')
const habits = ref([])
const dailyCheck = ref(null)
const weekStats = ref([])
const weekLoading = ref(false)
const savingPlan = ref(false)
const savingCheck = ref(false)
const planDialogVisible = ref(false)
const checkDialogVisible = ref(false)

const planForm = reactive({
  timePeriod: '上午',
  content: '',
  type: '',
  difficulty: 3
})

const checkForm = reactive({
  deviation: '',
  escapeReason: '',
  progressScore: 5
})

function planTypeTag(type) {
  const map = { 学习: '', 工作: 'success', 健康: 'warning', 生活: 'info' }
  return map[type] || ''
}

function intensityTag(val) {
  if (val <= 2) return 'info'
  if (val <= 4) return 'warning'
  return 'danger'
}

function intensityLabel(val) {
  if (val <= 2) return '轻松'
  if (val <= 4) return '适中'
  return '高强度'
}

async function fetchPlanData() {
  if (!planDate.value) return
  planLoading.value = true
  try {
    const data = await getDailyPlan(planDate.value)
    if (data) planList.value = data.records || data.list || Array.isArray(data) ? data : []
    else planList.value = []
  } catch (e) {
    planList.value = []
  } finally {
    planLoading.value = false
  }
}

async function handleGeneratePlan() {
  generating.value = true
  try {
    await generateTodayPlan()
    ElMessage.success('计划生成成功')
    fetchPlanData()
  } catch (e) {
    // handled in interceptor
  } finally {
    generating.value = false
  }
}

function openPlanDialog(row) {
  planForm.timePeriod = row.timePeriod || '上午'
  planForm.content = row.content || ''
  planForm.type = row.type || ''
  planForm.difficulty = row.difficulty || 3
  planDialogVisible.value = true
}

async function handleSavePlan() {
  savingPlan.value = true
  try {
    await savePlan({ ...planForm, date: planDate.value })
    ElMessage.success('保存成功')
    planDialogVisible.value = false
    fetchPlanData()
  } catch (e) {
    // handled in interceptor
  } finally {
    savingPlan.value = false
  }
}

async function fetchHabits() {
  try {
    const data = await getEliteHabits(habitCategory.value)
    if (data) habits.value = data.records || data.list || Array.isArray(data) ? data : []
    else habits.value = []
  } catch (e) {
    habits.value = []
  }
}

async function fetchDailyCheck() {
  if (!planDate.value) return
  try {
    const data = await getDailyCheck(planDate.value)
    dailyCheck.value = data || null
  } catch (e) {
    dailyCheck.value = null
  }
}

async function fetchWeekStats() {
  weekLoading.value = true
  try {
    const data = await getWeekCheckStats()
    if (data) weekStats.value = data.records || data.list || Array.isArray(data) ? data : []
    else weekStats.value = []
  } catch (e) {
    weekStats.value = []
  } finally {
    weekLoading.value = false
  }
}

function openCheckDialog() {
  checkForm.deviation = dailyCheck.value?.deviation || ''
  checkForm.escapeReason = dailyCheck.value?.escapeReason || ''
  checkForm.progressScore = dailyCheck.value?.progressScore || 5
  checkDialogVisible.value = true
}

async function handleSaveCheck() {
  savingCheck.value = true
  try {
    await saveCheck({
      date: planDate.value,
      ...checkForm
    })
    ElMessage.success('保存成功')
    checkDialogVisible.value = false
    fetchDailyCheck()
    fetchWeekStats()
  } catch (e) {
    // handled in interceptor
  } finally {
    savingCheck.value = false
  }
}

fetchPlanData()
fetchHabits()
fetchDailyCheck()
fetchWeekStats()
</script>

<style scoped>
.el-card { margin-bottom: 16px; }
</style>
