<template>
  <div class="page-container">
    <div class="page-header">
      <h2>读书阅读</h2>
    </div>

    <el-tabs v-model="activeTab" @tab-change="handleTabChange">
      <el-tab-pane label="财商赚钱" name="finance" />
      <el-tab-pane label="心理成长" name="psychology" />
      <el-tab-pane label="人文休闲" name="humanity" />
    </el-tabs>

    <div class="card-grid">
      <div class="stat-card">
        <div class="stat-value">{{ stats.totalMinutes || 0 }}</div>
        <div class="stat-label">总阅读时长(分钟)</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ stats.avgProgress || 0 }}%</div>
        <div class="stat-label">平均进度</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ stats.inProgress || 0 }}</div>
        <div class="stat-label">在读数量</div>
      </div>
    </div>

    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>书籍列表</span>
          <el-button type="primary" size="small" @click="openAddDialog">新增记录</el-button>
        </div>
      </template>
      <el-table :data="books" stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="bookName" label="书名" min-width="160" show-overflow-tooltip />
        <el-table-column prop="bookType" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="typeTag(row.bookType)" size="small">{{ typeLabel(row.bookType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="minutes" label="阅读时长(分)" width="120" align="center" />
        <el-table-column prop="progress" label="进度" width="140">
          <template #default="{ row }">
            <el-progress :percentage="row.progress || 0" :stroke-width="14" />
          </template>
        </el-table-column>
        <el-table-column prop="notes" label="笔记预览" min-width="160" show-overflow-tooltip />
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
        @current-change="fetchBooks"
      />
    </el-card>

    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑记录' : '新增记录'" width="520px">
      <el-form :model="form" label-position="top">
        <el-form-item label="书籍类型">
          <el-select v-model="form.bookType" style="width: 100%;">
            <el-option label="财商赚钱" value="finance" />
            <el-option label="心理成长" value="psychology" />
            <el-option label="人文休闲" value="humanity" />
          </el-select>
        </el-form-item>
        <el-form-item label="书名">
          <el-input v-model="form.bookName" placeholder="请输入书名" />
        </el-form-item>
        <el-form-item label="阅读时长(分钟)">
          <el-input-number v-model="form.minutes" :min="0" :max="1440" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="阅读进度 (0-100%)">
          <el-slider v-model="form.progress" :min="0" :max="100" show-input />
        </el-form-item>
        <el-form-item label="读书笔记">
          <el-input v-model="form.notes" type="textarea" :rows="4" placeholder="记录你的读书感悟" />
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
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { getBookPage, getBookStats, saveBook, updateBook } from '@/api'

const activeTab = ref('finance')
const loading = ref(false)
const saving = ref(false)
const books = ref([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
const stats = ref({})
const dialogVisible = ref(false)
const isEdit = ref(false)
const editId = ref(null)

const form = reactive({
  bookType: 'finance',
  bookName: '',
  minutes: 0,
  progress: 0,
  notes: ''
})

const typeMap = {
  finance: { label: '财商赚钱', tag: 'warning' },
  psychology: { label: '心理成长', tag: 'success' },
  humanity: { label: '人文休闲', tag: '' }
}

function typeLabel(type) {
  return typeMap[type]?.label || type
}

function typeTag(type) {
  return typeMap[type]?.tag || ''
}

async function fetchStats() {
  try {
    const data = await getBookStats()
    if (data) stats.value = data
  } catch (e) {
    // handled in interceptor
  }
}

async function fetchBooks() {
  loading.value = true
  try {
    const data = await getBookPage(page.value, size.value, activeTab.value)
    if (data) {
      books.value = data.records || data.list || []
      total.value = data.total || 0
    }
  } catch (e) {
    // handled in interceptor
  } finally {
    loading.value = false
  }
}

function handleTabChange() {
  page.value = 1
  fetchBooks()
}

function openAddDialog() {
  isEdit.value = false
  editId.value = null
  form.bookType = activeTab.value
  form.bookName = ''
  form.minutes = 0
  form.progress = 0
  form.notes = ''
  dialogVisible.value = true
}

function openEditDialog(row) {
  isEdit.value = true
  editId.value = row.id
  form.bookType = row.bookType
  form.bookName = row.bookName || ''
  form.minutes = row.minutes || 0
  form.progress = row.progress || 0
  form.notes = row.notes || ''
  dialogVisible.value = true
}

async function handleSave() {
  if (!form.bookName.trim()) {
    ElMessage.warning('请输入书名')
    return
  }
  saving.value = true
  try {
    if (isEdit.value && editId.value) {
      await updateBook({ id: editId.value, ...form })
      ElMessage.success('更新成功')
    } else {
      await saveBook({ ...form })
      ElMessage.success('保存成功')
    }
    dialogVisible.value = false
    fetchBooks()
    fetchStats()
  } catch (e) {
    // handled in interceptor
  } finally {
    saving.value = false
  }
}

fetchStats()
fetchBooks()
</script>

<style scoped>
.el-card { margin-bottom: 16px; }
</style>
