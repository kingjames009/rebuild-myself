<template>
  <div class="page-container">
    <div class="page-header">
      <h2>目标管理</h2>
      <el-button type="primary" @click="openAddDialog">新增目标</el-button>
    </div>

    <el-card>
      <el-tabs v-model="levelTab" @tab-change="fetchData">
        <el-tab-pane v-for="tab in levelTabs" :key="tab.value" :label="tab.label" :name="tab.value" />
      </el-tabs>

      <el-table :data="goalList" stripe v-loading="loading" empty-text="暂无目标数据">
        <el-table-column prop="title" label="目标标题" min-width="160" />
        <el-table-column prop="type" label="类型" width="120">
          <template #default="{ row }">
            <el-tag :type="typeTag(row.type)" size="small">{{ row.type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="进度" width="180">
          <template #default="{ row }">
            <el-progress :percentage="row.progress || 0" :status="progressStatus(row.progress)" />
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === '进行中' ? 'primary' : 'success'" size="small">
              {{ row.status || '进行中' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="targetDate" label="目标日期" width="120" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openProgressDialog(row)">更新进度</el-button>
            <el-button type="warning" link size="small" @click="openEditDialog(row)">编辑</el-button>
            <el-button type="danger" link size="small" @click="handleDelete(row)">删除</el-button>
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
        @current-change="fetchData"
      />
    </el-card>

    <!-- Add / Edit Dialog -->
    <el-dialog v-model="showDialog" :title="isEdit ? '编辑目标' : '新增目标'" width="520px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="目标标题" prop="title">
          <el-input v-model="form.title" placeholder="输入目标标题" />
        </el-form-item>
        <el-form-item label="目标描述" prop="content">
          <el-input v-model="form.content" type="textarea" :rows="3" placeholder="描述你的目标" />
        </el-form-item>
        <el-form-item label="类型" prop="type">
          <el-select v-model="form.type" placeholder="选择类型" style="width:100%">
            <el-option label="健康" value="健康" />
            <el-option label="学习" value="学习" />
            <el-option label="工作" value="工作" />
            <el-option label="财务" value="财务" />
            <el-option label="生活" value="生活" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="层级" prop="level">
          <el-select v-model="form.level" placeholder="选择层级" style="width:100%">
            <el-option v-for="tab in levelTabs" :key="tab.value" :label="tab.label" :value="tab.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="目标日期" prop="targetDate">
          <el-date-picker v-model="form.targetDate" type="date" placeholder="选择日期" style="width:100%" value-format="YYYY-MM-DD" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="handleSubmit">保存</el-button>
      </template>
    </el-dialog>

    <!-- Progress Update Dialog -->
    <el-dialog v-model="showProgressDialog" title="更新进度" width="400px" destroy-on-close>
      <div style="text-align:center;padding:20px 0">
        <el-statistic :value="progressForm.progress" suffix="%">
          <template #title>当前进度</template>
        </el-statistic>
        <el-slider v-model="progressForm.progress" :min="0" :max="100" :step="1" show-input style="margin-top:24px" />
      </div>
      <template #footer>
        <el-button @click="showProgressDialog = false">取消</el-button>
        <el-button type="primary" :loading="progressLoading" @click="handleUpdateProgress">确认更新</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getGoalPage, saveGoal, updateGoal, deleteGoal, updateGoalProgress } from '@/api'

const levelTabs = [
  { label: '长期', value: 'long' },
  { label: '年度', value: 'year' },
  { label: '月度', value: 'month' },
  { label: '每日', value: 'day' }
]

const levelTab = ref('long')
const goalList = ref([])
const loading = ref(false)
const total = ref(0)
const page = ref(1)
const size = ref(10)

// Form
const showDialog = ref(false)
const isEdit = ref(false)
const editingId = ref(null)
const submitLoading = ref(false)
const formRef = ref(null)
const form = reactive({
  title: '',
  content: '',
  type: '学习',
  level: 'long',
  targetDate: ''
})

const rules = {
  title: [{ required: true, message: '请输入目标标题', trigger: 'blur' }],
  type: [{ required: true, message: '请选择类型', trigger: 'change' }],
  level: [{ required: true, message: '请选择层级', trigger: 'change' }]
}

// Progress
const showProgressDialog = ref(false)
const progressLoading = ref(false)
const progressForm = reactive({ id: null, progress: 0 })

const typeTag = (type) => {
  const map = { 健康: 'success', 学习: 'primary', 工作: 'warning', 财务: 'danger', 生活: 'info' }
  return map[type] || ''
}

const progressStatus = (p) => {
  if (p >= 100) return 'success'
  if (p > 0) return ''
  return ''
}

const fetchData = async () => {
  loading.value = true
  try {
    const res = await getGoalPage(page.value, size.value, levelTab.value)
    goalList.value = res.records || []
    total.value = res.total || 0
  } catch (e) {
    // handled
  } finally {
    loading.value = false
  }
}

const openAddDialog = () => {
  isEdit.value = false
  editingId.value = null
  form.title = ''
  form.content = ''
  form.type = '学习'
  form.level = levelTab.value
  form.targetDate = ''
  showDialog.value = true
}

const openEditDialog = (row) => {
  isEdit.value = true
  editingId.value = row.id
  form.title = row.title
  form.content = row.content || ''
  form.type = row.type
  form.level = row.level || levelTab.value
  form.targetDate = row.targetDate || ''
  showDialog.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitLoading.value = true
  try {
    const data = { ...form }
    if (isEdit.value && editingId.value) {
      data.id = editingId.value
      await updateGoal(data)
      ElMessage.success('更新成功')
    } else {
      await saveGoal(data)
      ElMessage.success('新增成功')
    }
    showDialog.value = false
    fetchData()
  } catch (e) {
    // handled
  } finally {
    submitLoading.value = false
  }
}

const handleDelete = (row) => {
  ElMessageBox.confirm('确定删除该目标吗？', '提示', { type: 'warning' }).then(async () => {
    await deleteGoal(row.id)
    ElMessage.success('删除成功')
    fetchData()
  }).catch(() => {})
}

const openProgressDialog = (row) => {
  progressForm.id = row.id
  progressForm.progress = row.progress || 0
  showProgressDialog.value = true
}

const handleUpdateProgress = async () => {
  progressLoading.value = true
  try {
    await updateGoalProgress({ id: progressForm.id, progress: progressForm.progress })
    ElMessage.success('进度已更新')
    showProgressDialog.value = false
    fetchData()
  } catch (e) {
    // handled
  } finally {
    progressLoading.value = false
  }
}

onMounted(fetchData)
</script>

<style scoped>
.pagination {
  margin-top: 16px;
  justify-content: center;
}
</style>
