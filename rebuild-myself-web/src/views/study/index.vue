<template>
  <div class="page-container">
    <div class="page-header">
      <h2>学习中心</h2>
      <el-button type="primary" @click="openAddDialog">新增记录</el-button>
    </div>

    <el-card>
      <el-tabs v-model="trackTab" @tab-change="fetchData">
        <el-tab-pane v-for="tab in trackTabs" :key="tab.value" :label="tab.label" :name="tab.value" />
      </el-tabs>

      <!-- Study Stats -->
      <el-row :gutter="16" class="stat-row">
        <el-col :span="8" v-for="stat in trackStats" :key="stat.label">
          <el-card shadow="hover" class="stat-card">
            <div class="stat-value" :style="{ color: stat.color }">{{ stat.value }}</div>
            <div class="stat-label">{{ stat.label }}</div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Records Table -->
      <el-table :data="recordList" stripe v-loading="loading" empty-text="暂无学习记录" style="margin-top:16px">
        <el-table-column prop="content" label="学习内容" min-width="180" show-overflow-tooltip />
        <el-table-column prop="minutes" label="时长(分)" width="100" sortable />
        <el-table-column label="难度" width="100">
          <template #default="{ row }">
            <el-tag :type="difficultyTag(row.difficulty)" size="small">{{ row.difficulty || '--' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="逃避状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.escape ? 'danger' : 'success'" size="small">{{ row.escape ? '逃避' : '专注' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="studyDate" label="日期" width="120">
          <template #default="{ row }">
            {{ row.studyDate ? dayjs(row.studyDate).format('YYYY-MM-DD') : '--' }}
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-if="total > 0"
        v-model:current-page="page"
        :page-size="size"
        :total="total"
        layout="prev, pager, next"
        class="pagination"
        @current-change="fetchRecords"
      />
    </el-card>

    <!-- Add Dialog -->
    <el-dialog v-model="showDialog" title="新增学习记录" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="所属轨道" prop="trackType">
          <el-select v-model="form.trackType" placeholder="选择轨道" style="width:100%">
            <el-option v-for="tab in trackTabs" :key="tab.value" :label="tab.label" :value="tab.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="学习内容" prop="content">
          <el-input v-model="form.content" type="textarea" :rows="2" placeholder="学习内容描述" />
        </el-form-item>
        <el-form-item label="时长(分)" prop="minutes">
          <el-input-number v-model="form.minutes" :min="1" :step="5" style="width:100%" />
        </el-form-item>
        <el-form-item label="难度" prop="difficulty">
          <el-slider v-model="form.difficulty" :min="1" :max="5" :step="1" show-input show-stops :marks="{1:'简单',3:'中等',5:'困难'}" />
        </el-form-item>
        <el-form-item label="逃避状态">
          <el-radio-group v-model="form.escape">
            <el-radio :label="false">专注</el-radio>
            <el-radio :label="true">逃避</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="handleSubmit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getStudyPage, getStudyStats, saveStudy } from '@/api'
import dayjs from 'dayjs'

const trackTabs = [
  { label: '英语演讲', value: 'english' },
  { label: 'AI学习', value: 'ai' },
  { label: '应用开发', value: 'dev' }
]

const trackTab = ref('english')

const trackStats = ref([
  { label: '总时长(分)', value: 0, color: '#409EFF' },
  { label: '平均难度', value: '0', color: '#E6A23C' },
  { label: '逃避率', value: '0%', color: '#F56C6C' }
])

const recordList = ref([])
const loading = ref(false)
const page = ref(1)
const size = ref(10)
const total = ref(0)

// Form
const showDialog = ref(false)
const submitLoading = ref(false)
const formRef = ref(null)
const form = reactive({
  trackType: 'english',
  content: '',
  minutes: 30,
  difficulty: 3,
  escape: false
})

const rules = {
  content: [{ required: true, message: '请输入学习内容', trigger: 'blur' }],
  minutes: [{ required: true, message: '请输入学习时长', trigger: 'change' }]
}

const difficultyTag = (d) => {
  if (!d) return 'info'
  if (d <= 2) return 'success'
  if (d <= 4) return 'warning'
  return 'danger'
}

const fetchRecords = async () => {
  loading.value = true
  try {
    const res = await getStudyPage(page.value, size.value, trackTab.value)
    recordList.value = res.records || []
    total.value = res.total || 0
  } catch (e) {
    // handled
  } finally {
    loading.value = false
  }
}

const fetchStats = async () => {
  try {
    const res = await getStudyStats()
    if (res && res.trackStats) {
      const current = res.trackStats[trackTab.value]
      if (current) {
        trackStats.value[0].value = current.totalMinutes || 0
        trackStats.value[1].value = current.avgDifficulty || '0'
        trackStats.value[2].value = (current.escapeRate || 0) + '%'
      }
    }
  } catch (e) {
    // handled
  }
}

const fetchData = () => {
  fetchRecords()
  fetchStats()
}

const openAddDialog = () => {
  form.trackType = trackTab.value
  form.content = ''
  form.minutes = 30
  form.difficulty = 3
  form.escape = false
  showDialog.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitLoading.value = true
  try {
    await saveStudy({
      ...form,
      studyDate: dayjs().format('YYYY-MM-DD')
    })
    ElMessage.success('新增成功')
    showDialog.value = false
    fetchData()
  } catch (e) {
    // handled
  } finally {
    submitLoading.value = false
  }
}

onMounted(fetchData)
</script>

<style scoped>
.stat-row {
  margin-bottom: 0;
}
.stat-card {
  text-align: center;
}
.stat-value {
  font-size: 26px;
  font-weight: 700;
}
.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}
.pagination {
  margin-top: 16px;
  justify-content: center;
}
</style>
