<template>
  <div class="page-container">
    <div class="page-header">
      <h2>AI复盘</h2>
    </div>

    <el-card>
      <div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">
        <el-radio-group v-model="cycleType">
          <el-radio-button :value="1">日</el-radio-button>
          <el-radio-button :value="2">周</el-radio-button>
          <el-radio-button :value="3">月</el-radio-button>
          <el-radio-button :value="4">年</el-radio-button>
        </el-radio-group>
        <el-button type="primary" :loading="generating" @click="handleGenerate">
          生成复盘报告
        </el-button>
      </div>
    </el-card>

    <el-card v-if="currentReport" style="margin-top: 16px;">
      <template #header>
        <span>{{ cycleTypeLabel }}度复盘报告</span>
      </template>
      <div v-loading="generating" style="min-height: 120px; white-space: pre-wrap; line-height: 1.8; font-size: 14px; color: #303133;">
        {{ currentReport }}
      </div>
    </el-card>

    <el-card style="margin-top: 16px;">
      <template #header><span>历史报告</span></template>
      <el-table :data="reports" stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="cycleType" label="周期类型" width="100">
          <template #default="{ row }">
            <el-tag :type="cycleTag(row.cycleType)" size="small">{{ cycleLabel(row.cycleType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="cycleRange" label="周期范围" width="220" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button text size="small" @click="viewReport(row)">查看</el-button>
            <el-button text size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-if="total > 0"
        v-model:current-page="page"
        :page-size="size"
        :total="total"
        layout="prev, pager, next"
        style="margin-top: 16px; justify-content: center;"
        @current-change="fetchReports"
      />
    </el-card>

    <el-dialog v-model="viewDialogVisible" title="复盘报告详情" width="700px">
      <div
        style="max-height: 520px; overflow-y: auto; white-space: pre-wrap; line-height: 1.8; font-size: 14px;"
      >
        {{ viewingContent }}
      </div>
      <template #footer>
        <el-button @click="viewDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { generateReport, getReportPage } from '@/api'

const cycleType = ref(2)
const generating = ref(false)
const loading = ref(false)
const currentReport = ref('')
const reports = ref([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
const viewDialogVisible = ref(false)
const viewingContent = ref('')

const cycleTypeMap = {
  1: { label: '日', tag: 'success' },
  2: { label: '周', tag: 'warning' },
  3: { label: '月', tag: '' },
  4: { label: '年', tag: 'danger' }
}

const cycleTypeLabel = computed(() => cycleTypeMap[cycleType.value]?.label || '')
function cycleLabel(type) { return cycleTypeMap[type]?.label || '-' }
function cycleTag(type) { return cycleTypeMap[type]?.tag || '' }

async function handleGenerate() {
  generating.value = true
  currentReport.value = ''
  try {
    const data = await generateReport(cycleType.value)
    currentReport.value = data?.reportContent || '报告内容为空'
    ElMessage.success('报告生成成功')
    fetchReports()
  } catch (e) {
    // handled in interceptor
  } finally {
    generating.value = false
  }
}

async function fetchReports() {
  loading.value = true
  try {
    const data = await getReportPage(page.value, size.value)
    if (data) {
      reports.value = data.records || []
      total.value = data.total || 0
    }
  } catch (e) {
    // handled in interceptor
  } finally {
    loading.value = false
  }
}

function viewReport(row) {
  viewingContent.value = row.reportContent || '暂无内容'
  viewDialogVisible.value = true
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm('确定删除该报告吗？', '提示', { type: 'warning' })
    const { deleteReport } = await import('@/api')
    if (deleteReport) {
      await deleteReport(row.reportId)
      ElMessage.success('删除成功')
      fetchReports()
    }
  } catch (e) {
    // cancelled
  }
}

fetchReports()
</script>

<style scoped>
.el-card { margin-bottom: 16px; }
</style>
