<template>
  <div class="page-container">
    <div class="page-header">
      <h2>副业落地</h2>
    </div>

    <el-radio-group v-model="activeType" style="margin-bottom: 16px;">
      <el-radio-button value="english">英语方向</el-radio-button>
      <el-radio-button value="ai">AI方向</el-radio-button>
      <el-radio-button value="dev">开发综合</el-radio-button>
    </el-radio-group>

    <div class="card-grid">
      <div class="stat-card" v-for="item in progressList" :key="item.type">
        <div class="stat-label">{{ item.label }}</div>
        <div style="margin-top: 8px;">
          <el-progress :percentage="item.progress" :color="item.color" />
        </div>
      </div>
    </div>

    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>行动记录</span>
          <el-button type="primary" size="small" @click="openAddDialog">新增记录</el-button>
        </div>
      </template>
      <el-table :data="records" stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="typeTag(row.type)" size="small">{{ typeLabel(row.type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="dailyAction" label="今日行动" min-width="160" show-overflow-tooltip />
        <el-table-column prop="progress" label="进度" width="140">
          <template #default="{ row }">
            <el-progress :percentage="row.progress" :stroke-width="14" />
          </template>
        </el-table-column>
        <el-table-column prop="energyCost" label="精力消耗" width="100" align="center">
          <template #default="{ row }">
            <el-rate v-model="row.energyCost" disabled :max="5" />
          </template>
        </el-table-column>
        <el-table-column prop="obstacle" label="障碍" width="120" show-overflow-tooltip />
        <el-table-column prop="date" label="日期" width="100" />
        <el-table-column label="操作" width="80" fixed="right">
          <template #default="{ row }">
            <el-button text size="small" @click="openEditDialog(row)">编辑</el-button>
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
        @current-change="fetchRecords"
      />
    </el-card>

    <el-card style="margin-top: 16px;">
      <template #header><span>障碍分析</span></template>
      <div v-if="obstacleList.length === 0" style="color: #999; padding: 20px 0; text-align: center;">暂无障碍数据</div>
      <div v-for="item in obstacleList" :key="item.reason" style="display: flex; align-items: center; margin-bottom: 12px;">
        <span style="width: 160px; font-size: 13px;">{{ item.reason }}</span>
        <el-progress :percentage="item.percent" :stroke-width="16" style="flex: 1;" />
        <span style="width: 50px; text-align: right; font-size: 12px; color: #999;">{{ item.count }}次</span>
      </div>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑记录' : '新增记录'" width="520px">
      <el-form :model="form" label-position="top">
        <el-form-item label="类型">
          <el-select v-model="form.type" style="width: 100%;">
            <el-option label="英语方向" value="english" />
            <el-option label="AI方向" value="ai" />
            <el-option label="开发综合" value="dev" />
          </el-select>
        </el-form-item>
        <el-form-item label="今日行动">
          <el-input v-model="form.dailyAction" type="textarea" :rows="3" placeholder="描述你今天做了哪些行动" />
        </el-form-item>
        <el-form-item label="进度 (0-100%)">
          <el-slider v-model="form.progress" :min="0" :max="100" show-input />
        </el-form-item>
        <el-form-item label="精力消耗">
          <el-slider v-model="form.energyCost" :min="0" :max="5" :step="1" show-input />
        </el-form-item>
        <el-form-item label="障碍 / 卡点">
          <el-input v-model="form.obstacle" type="textarea" :rows="2" placeholder="遇到的障碍或卡点" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { getSidelinePage, getSidelineProgress, saveSideline, updateSideline } from '@/api'

const activeType = ref('english')
const loading = ref(false)
const saving = ref(false)
const records = ref([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
const progressList = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const editId = ref(null)

const form = reactive({
  type: 'english',
  dailyAction: '',
  progress: 0,
  energyCost: 3,
  obstacle: ''
})

const typeMap = {
  english: { label: '英语方向', color: '#409EFF', tag: '' },
  ai: { label: 'AI方向', color: '#67C23A', tag: 'success' },
  dev: { label: '开发综合', color: '#E6A23C', tag: 'warning' }
}

function typeLabel(type) {
  return typeMap[type]?.label || type
}

function typeTag(type) {
  return typeMap[type]?.tag || ''
}

async function fetchProgress() {
  try {
    const data = await getSidelineProgress()
    if (data) {
      const colors = { english: '#409EFF', ai: '#67C23A', dev: '#E6A23C' }
      progressList.value = Object.entries(data).map(([key, val]) => ({
        type: key,
        label: typeMap[key]?.label || key,
        progress: val,
        color: colors[key] || '#409EFF'
      }))
    }
  } catch (e) {
    // handled in interceptor
  }
}

async function fetchRecords() {
  loading.value = true
  try {
    const data = await getSidelinePage(page.value, size.value)
    if (data) {
      records.value = data.records || data.list || []
      total.value = data.total || 0
    }
  } catch (e) {
    // handled in interceptor
  } finally {
    loading.value = false
  }
}

const obstacleList = computed(() => {
  const map = {}
  records.value.forEach(r => {
    if (r.obstacle) {
      map[r.obstacle] = (map[r.obstacle] || 0) + 1
    }
  })
  const keys = Object.keys(map)
  if (keys.length === 0) return []
  const max = Math.max(...Object.values(map))
  return keys.map(reason => ({
    reason,
    count: map[reason],
    percent: Math.round((map[reason] / max) * 100)
  })).sort((a, b) => b.count - a.count)
})

function openAddDialog() {
  isEdit.value = false
  editId.value = null
  form.type = activeType.value
  form.dailyAction = ''
  form.progress = 0
  form.energyCost = 3
  form.obstacle = ''
  dialogVisible.value = true
}

function openEditDialog(row) {
  isEdit.value = true
  editId.value = row.id
  form.type = row.type
  form.dailyAction = row.dailyAction || ''
  form.progress = row.progress || 0
  form.energyCost = row.energyCost || 3
  form.obstacle = row.obstacle || ''
  dialogVisible.value = true
}

async function handleSave() {
  if (!form.dailyAction.trim()) {
    ElMessage.warning('请输入今日行动')
    return
  }
  saving.value = true
  try {
    if (isEdit.value && editId.value) {
      await updateSideline({ id: editId.value, ...form })
      ElMessage.success('更新成功')
    } else {
      await saveSideline({ ...form })
      ElMessage.success('保存成功')
    }
    dialogVisible.value = false
    fetchRecords()
    fetchProgress()
  } catch (e) {
    // handled in interceptor
  } finally {
    saving.value = false
  }
}

watch(activeType, () => {
  page.value = 1
  fetchRecords()
})

fetchProgress()
fetchRecords()
</script>

<style scoped>
.el-card { margin-bottom: 16px; }
</style>
