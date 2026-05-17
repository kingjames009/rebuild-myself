<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h2>你好，{{ nickname }}</h2>
        <p class="date-text">{{ todayDate }}</p>
      </div>
    </div>

    <!-- Stat Cards -->
    <el-row :gutter="16" class="stat-row">
      <el-col :xs="12" :sm="6" v-for="stat in statCards" :key="stat.label">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value" :style="{ color: stat.color }">{{ stat.value }}</div>
          <div class="stat-label">{{ stat.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Quick Actions -->
    <el-card class="section-card">
      <template #header><span>快捷操作</span></template>
      <el-row :gutter="16">
        <el-col :xs="12" :sm="6" v-for="action in quickActions" :key="action.label">
          <el-button :type="action.type" class="action-btn" @click="action.handler">
            {{ action.label }}
          </el-button>
        </el-col>
      </el-row>
    </el-card>

    <!-- Today's Plan -->
    <el-card class="section-card">
      <template #header><span>今日模型计划</span></template>
      <el-table :data="planList" stripe v-loading="planLoading" empty-text="今日暂无计划">
        <el-table-column prop="timePeriod" label="时段" width="120" />
        <el-table-column prop="planContent" label="内容" min-width="200" />
        <el-table-column prop="planType" label="类型" width="120">
          <template #default="{ row }">
            <el-tag :type="planTypeTag(row.planType)" size="small">{{ planTypeLabel(row.planType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="difficulty" label="难度" width="100">
          <template #default="{ row }">
            <el-tag :type="difficultyTag(row.difficulty)" size="small">{{ row.difficulty }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Dialogs -->
    <el-dialog v-model="showRecordDialog" title="快捷记录" width="480px" destroy-on-close>
      <el-form :model="recordForm" label-width="80px">
        <el-form-item label="记录内容">
          <el-input v-model="recordForm.content" type="textarea" :rows="3" placeholder="写下你的记录..." />
        </el-form-item>
        <el-form-item label="记录类型">
          <el-select v-model="recordForm.recordType" placeholder="选择类型" style="width:100%">
            <el-option label="学习" :value="1" />
            <el-option label="作息" :value="2" />
            <el-option label="情绪" :value="3" />
            <el-option label="拖延" :value="4" />
            <el-option label="短视频" :value="5" />
            <el-option label="私密杂念" :value="6" />
            <el-option label="健康" :value="7" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRecordDialog = false">取消</el-button>
        <el-button type="primary" :loading="recordLoading" @click="submitRecord">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showTaskDialog" title="新增待办" width="480px" destroy-on-close>
      <el-form :model="taskForm" label-width="80px">
        <el-form-item label="待办内容">
          <el-input v-model="taskForm.taskTitle" placeholder="输入待办事项" />
        </el-form-item>
        <el-form-item label="优先级">
          <el-select v-model="taskForm.taskLevel" placeholder="选择" style="width:100%">
            <el-option label="重要紧急" :value="1" />
            <el-option label="重要不紧急" :value="2" />
            <el-option label="紧急不重要" :value="3" />
            <el-option label="不重要不紧急" :value="4" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showTaskDialog = false">取消</el-button>
        <el-button type="primary" :loading="taskLoading" @click="submitTask">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store/user'
import { ElMessage } from 'element-plus'
import { getDailyPlan, getRecordPage, getTaskList, getBehaviorStats, saveRecord, saveTask } from '@/api'
import dayjs from 'dayjs'

const router = useRouter()
const userStore = useUserStore()

const nickname = computed(() => userStore.nickname)
const todayDate = computed(() => dayjs().format('YYYY年M月D日 dddd'))

const statCards = ref([
  { label: '今日记录数', value: 0, color: '#409EFF' },
  { label: '今日待办', value: 0, color: '#67C23A' },
  { label: '行为干预成功率', value: '0%', color: '#E6A23C' },
  { label: '学习总时长(分钟)', value: 0, color: '#F56C6C' }
])

const quickActions = [
  { label: '快捷记录', type: 'primary', handler: () => openRecordDialog() },
  { label: '新增待办', type: 'success', handler: () => openTaskDialog() },
  { label: '行为干预', type: 'warning', handler: () => router.push('/behavior') },
  { label: 'AI复盘', type: 'danger', handler: () => router.push('/report') }
]

// Plan
const planList = ref([])
const planLoading = ref(false)

// Record dialog
const showRecordDialog = ref(false)
const recordLoading = ref(false)
const recordForm = reactive({ content: '', recordType: 1 })

// Task dialog
const showTaskDialog = ref(false)
const taskLoading = ref(false)
const taskForm = reactive({ taskTitle: '', taskLevel: 1 })

const planTypeLabels = { 0: '综合', 1: '学习', 2: '副业', 3: '阅读', 4: '休闲', 5: '心理' }
const planTypeLabel = (type) => planTypeLabels[type] || '综合'
const planTypeTag = (type) => {
  const map = { 0: 'info', 1: 'primary', 2: 'success', 3: 'warning', 4: 'danger', 5: '' }
  return map[type] || 'info'
}

const difficultyTag = (diff) => {
  if (diff >= 4) return 'danger'
  if (diff >= 3) return 'warning'
  return 'success'
}

const fetchData = async () => {
  try {
    planLoading.value = true
    const today = dayjs().format('YYYY-MM-DD')
    const [planRes, recordRes, taskRes, statsRes] = await Promise.all([
      getDailyPlan(today).catch(() => []),
      getRecordPage(1, 999).catch(() => ({ records: [], total: 0 })),
      getTaskList(today).catch(() => []),
      getBehaviorStats(today, today).catch(() => ({}))
    ])
    planList.value = Array.isArray(planRes) ? planRes : []
    statCards.value[0].value = recordRes.total || 0
    statCards.value[1].value = Array.isArray(taskRes) ? taskRes.length : 0
    statCards.value[2].value = statsRes.successRate != null ? statsRes.successRate + '%' : '0%'
  } catch (e) {
    // silent
  } finally {
    planLoading.value = false
  }
}

const openRecordDialog = () => {
  recordForm.content = ''
  recordForm.recordType = 1
  showRecordDialog.value = true
}

const submitRecord = async () => {
  if (!recordForm.content) {
    ElMessage.warning('请输入记录内容')
    return
  }
  recordLoading.value = true
  try {
    await saveRecord({
      content: recordForm.content,
      recordType: recordForm.recordType,
      recordDate: dayjs().format('YYYY-MM-DD')
    })
    ElMessage.success('记录成功')
    showRecordDialog.value = false
    fetchData()
  } catch (e) {
    // handled
  } finally {
    recordLoading.value = false
  }
}

const openTaskDialog = () => {
  taskForm.taskTitle = ''
  taskForm.taskLevel = 1
  showTaskDialog.value = true
}

const submitTask = async () => {
  if (!taskForm.taskTitle) {
    ElMessage.warning('请输入待办内容')
    return
  }
  taskLoading.value = true
  try {
    await saveTask({
      taskTitle: taskForm.taskTitle,
      taskLevel: taskForm.taskLevel,
      taskDate: dayjs().format('YYYY-MM-DD')
    })
    ElMessage.success('新增待办成功')
    showTaskDialog.value = false
    fetchData()
  } catch (e) {
    // handled
  } finally {
    taskLoading.value = false
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.stat-row {
  margin-bottom: 16px;
}
.stat-card {
  text-align: center;
}
.stat-value {
  font-size: 28px;
  font-weight: 700;
}
.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}
.section-card {
  margin-bottom: 16px;
}
.action-btn {
  width: 100%;
  height: 48px;
  font-size: 15px;
}
.date-text {
  color: #909399;
  font-size: 14px;
  margin: 4px 0 0 0;
}
.page-header h2 {
  margin: 0;
}
</style>
