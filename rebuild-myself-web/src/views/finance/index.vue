<template>
  <div class="page-container">
    <div class="page-header">
      <h2>财务行动</h2>
      <el-button type="primary" @click="openAddDialog">新增记录</el-button>
    </div>

    <!-- Week Stats -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8" v-for="stat in weekStats" :key="stat.label">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value" :style="{ color: stat.color }">{{ stat.value }}</div>
          <div class="stat-label">{{ stat.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Escape Warning -->
    <el-card class="section-card">
      <template #header>
        <span>逃避状态预警</span>
        <el-tag v-if="escapeLevel === 'high'" type="danger" effect="dark" style="margin-left:12px">高逃避风险</el-tag>
        <el-tag v-else-if="escapeLevel === 'medium'" type="warning" effect="dark" style="margin-left:12px">中等逃避</el-tag>
        <el-tag v-else type="success" effect="dark" style="margin-left:12px">状态良好</el-tag>
      </template>
      <div v-if="recentRecords.length > 0" style="display:flex;align-items:center;gap:24px">
        <div style="flex:1">
          <div style="display:flex;justify-content:space-between;margin-bottom:4px">
            <span style="font-size:14px">近期逃避指数</span>
            <span style="font-size:14px;font-weight:600">{{ recentEscapeAvg.toFixed(1) }} / 10</span>
          </div>
          <el-progress
            :percentage="recentEscapeAvg * 10"
            :color="escapeProgressColor"
            :stroke-width="24"
            :format="() => ''"
          />
        </div>
        <div style="text-align:center;min-width:120px">
          <el-statistic :value="recentEscapeAvg.toFixed(1)" suffix="/10">
            <template #title>平均逃避</template>
          </el-statistic>
        </div>
      </div>
      <div v-else style="text-align:center;padding:20px 0;color:#999">
        <el-empty description="暂无数据" />
      </div>
    </el-card>

    <!-- Records Table -->
    <el-card class="section-card">
      <template #header><span>财务记录</span></template>
      <el-table :data="recordList" stripe v-loading="loading" empty-text="暂无记录">
        <el-table-column prop="occurDate" label="日期" width="120">
          <template #default="{ row }">
            {{ row.occurDate ? dayjs(row.occurDate).format('YYYY-MM-DD') : '--' }}
          </template>
        </el-table-column>
        <el-table-column label="压力值" width="100">
          <template #default="{ row }">
            <el-rate v-model="row.pressure" :max="10" :low-threshold="4" :high-threshold="7" disabled size="small" show-score score-template="{value}分" />
          </template>
        </el-table-column>
        <el-table-column prop="gapAmount" label="缺口金额" width="120">
          <template #default="{ row }">
            <span :style="{ color: row.gapAmount > 0 ? '#F56C6C' : '#67C23A', fontWeight: 600 }">
              {{ row.gapAmount ? '¥' + row.gapAmount : '¥0' }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="actionMinutes" label="行动时长(分)" width="120" />
        <el-table-column label="逃避状态" width="120">
          <template #default="{ row }">
            <el-tag
              :type="row.escapeState >= 7 ? 'danger' : row.escapeState >= 4 ? 'warning' : 'success'"
              size="small"
            >
              {{ row.escapeState || 0 }}/10
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="incomeRecord" label="收入说明" min-width="160" show-overflow-tooltip />
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
    <el-dialog v-model="showDialog" title="新增财务记录" width="520px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="120px">
        <el-form-item label="压力值" prop="pressure">
          <el-slider v-model="form.pressure" :min="1" :max="10" :step="1" show-input show-stops :marks="{1:'1',5:'5',10:'10'}" />
        </el-form-item>
        <el-form-item label="缺口金额(元)" prop="gapAmount">
          <el-input-number v-model="form.gapAmount" :min="0" :step="100" style="width:100%" />
        </el-form-item>
        <el-form-item label="收入说明" prop="incomeRecord">
          <el-input v-model="form.incomeRecord" type="textarea" :rows="2" placeholder="描述收入或支出情况" />
        </el-form-item>
        <el-form-item label="逃避状态" prop="escapeState">
          <el-slider v-model="form.escapeState" :min="0" :max="10" :step="1" show-input show-stops :marks="{0:'无',5:'中等',10:'严重'}" />
        </el-form-item>
        <el-form-item label="行动时长(分)" prop="actionMinutes">
          <el-input-number v-model="form.actionMinutes" :min="0" :step="5" style="width:100%" />
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
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getFinancePage, getFinanceWeekStats, saveFinance } from '@/api'
import dayjs from 'dayjs'

const weekStats = ref([
  { label: '平均压力值', value: 0, color: '#F56C6C' },
  { label: '行动总时长(分)', value: 0, color: '#67C23A' },
  { label: '缺口金额合计', value: '¥0', color: '#E6A23C' }
])

const recordList = ref([])
const loading = ref(false)
const page = ref(1)
const size = ref(10)
const total = ref(0)
const recentRecords = ref([])
const recentEscapeAvg = ref(0)

const escapeLevel = computed(() => {
  const avg = recentEscapeAvg.value
  if (avg >= 7) return 'high'
  if (avg >= 4) return 'medium'
  return 'low'
})

const escapeProgressColor = computed(() => {
  const avg = recentEscapeAvg.value
  if (avg >= 7) return '#F56C6C'
  if (avg >= 4) return '#E6A23C'
  return '#67C23A'
})

// Form
const showDialog = ref(false)
const submitLoading = ref(false)
const formRef = ref(null)
const form = reactive({
  pressure: 5,
  gapAmount: 0,
  incomeRecord: '',
  escapeState: 0,
  actionMinutes: 0
})

const rules = {
  pressure: [{ required: true, message: '请设置压力值', trigger: 'change' }]
}

const fetchRecords = async () => {
  loading.value = true
  try {
    const res = await getFinancePage(page.value, size.value)
    recordList.value = res.records || []
    total.value = res.total || 0
  } catch (e) {
    // handled
  } finally {
    loading.value = false
  }
}

const fetchWeekStats = async () => {
  try {
    const res = await getFinanceWeekStats()
    weekStats.value[0].value = res.pressureAvg || 0
    weekStats.value[1].value = res.totalActionMinutes || 0
    weekStats.value[2].value = res.gapSum != null ? '¥' + res.gapSum : '¥0'
    recentRecords.value = res.recentRecords || []
    if (recentRecords.value.length > 0) {
      const totalEscape = recentRecords.value.reduce((sum, r) => sum + (r.escapeState || 0), 0)
      recentEscapeAvg.value = totalEscape / recentRecords.value.length
    }
  } catch (e) {
    // handled
  }
}

const openAddDialog = () => {
  form.pressure = 5
  form.gapAmount = 0
  form.incomeRecord = ''
  form.escapeState = 0
  form.actionMinutes = 0
  showDialog.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitLoading.value = true
  try {
    await saveFinance({ ...form })
    ElMessage.success('新增成功')
    showDialog.value = false
    fetchRecords()
    fetchWeekStats()
  } catch (e) {
    // handled
  } finally {
    submitLoading.value = false
  }
}

const fetchData = () => {
  fetchRecords()
  fetchWeekStats()
}

onMounted(fetchData)
</script>

<style scoped>
.stat-row {
  margin-bottom: 16px;
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
.section-card {
  margin-bottom: 16px;
}
.pagination {
  margin-top: 16px;
  justify-content: center;
}
</style>
