<template>
  <div class="page-container">
    <div class="page-header">
      <h2>行为矫正</h2>
      <el-button type="primary" @click="openAddDialog">新增干预</el-button>
    </div>

    <!-- Stat Cards -->
    <el-row :gutter="16" class="stat-row">
      <el-col :xs="12" :sm="6" v-for="card in typeStatCards" :key="card.label">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value">{{ card.rate }}%</div>
          <div class="stat-label" style="margin-top:4px">
            <el-tag :type="card.tag" size="small">{{ card.label }}</el-tag>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Filter -->
    <el-card class="section-card">
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:14px;color:#606266">筛选类型：</span>
        <el-select v-model="filterType" placeholder="全部类型" clearable style="width:160px" @change="fetchData">
          <el-option label="全部" :value="null" />
          <el-option v-for="item in behaviorTypes" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
      </div>
    </el-card>

    <!-- Intervention Records -->
    <el-card class="section-card">
      <template #header><span>干预记录</span></template>
      <el-table :data="behaviorList" stripe v-loading="loading" empty-text="暂无干预记录">
        <el-table-column prop="interveneType" label="类型" width="120">
          <template #default="{ row }">
            <el-tag :type="typeTag(row.interveneType)" size="small">{{ typeLabel(row.interveneType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="interveneTime" label="时间" width="160">
          <template #default="{ row }">
            {{ row.interveneTime ? dayjs(row.interveneTime).format('YYYY-MM-DD HH:mm') : '--' }}
          </template>
        </el-table-column>
        <el-table-column prop="isSuccess" label="是否成功" width="100">
          <template #default="{ row }">
            <el-tag :type="row.isSuccess === 1 ? 'success' : 'danger'" size="small">
              {{ row.isSuccess === 1 ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="moodBefore" label="干预前情绪" width="120" />
      </el-table>
    </el-card>

    <!-- Add Dialog -->
    <el-dialog v-model="showDialog" title="新增干预记录" width="480px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="行为类型" prop="interveneType">
          <el-select v-model="form.interveneType" placeholder="选择类型" style="width:100%">
            <el-option v-for="item in behaviorTypes" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="干预前情绪" prop="moodBefore">
          <el-input v-model="form.moodBefore" placeholder="描述当前情绪" />
        </el-form-item>
        <el-form-item label="是否成功">
          <el-select v-model="form.isSuccess" style="width:100%">
            <el-option label="成功" :value="1" />
            <el-option label="失败" :value="0" />
          </el-select>
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
import { getBehaviorList, getBehaviorStats, saveBehavior } from '@/api'
import dayjs from 'dayjs'

const behaviorTypes = [
  { label: '拖延', value: 1 },
  { label: '杂念', value: 2 },
  { label: '短视频', value: 3 },
  { label: '懒惰', value: 4 }
]

const typeStatCards = ref(
  behaviorTypes.map(t => ({ label: t.label, value: t.value, rate: 0, tag: typeTag(t.value) }))
)

const filterType = ref(null)
const behaviorList = ref([])
const loading = ref(false)

// Form
const showDialog = ref(false)
const submitLoading = ref(false)
const formRef = ref(null)
const form = reactive({
  interveneType: 1,
  moodBefore: '',
  isSuccess: 1
})

const rules = {
  interveneType: [{ required: true, message: '请选择行为类型', trigger: 'change' }]
}

const typeLabel = (t) => {
  const map = { 1: '拖延', 2: '杂念', 3: '短视频', 4: '懒惰' }
  return map[t] || '未知'
}

const typeTag = (t) => {
  const map = { 1: 'danger', 2: 'warning', 3: 'info', 4: '' }
  return map[t] || ''
}

const fetchData = async () => {
  loading.value = true
  try {
    const [listRes] = await Promise.all([
      getBehaviorList(filterType.value || undefined)
    ])
    behaviorList.value = Array.isArray(listRes) ? listRes : []

    // Compute per-type rates
    if (behaviorList.value.length > 0) {
      typeStatCards.value = behaviorTypes.map(t => {
        const items = behaviorList.value.filter(b => b.interveneType === t.value)
        const successCount = items.filter(b => b.isSuccess === 1).length
        const rate = items.length > 0 ? Math.round((successCount / items.length) * 100) : 0
        return { label: t.label, value: t.value, rate, tag: typeTag(t.value) }
      })
    }
  } catch (e) {
    // handled
  } finally {
    loading.value = false
  }
}

const openAddDialog = () => {
  form.interveneType = 1
  form.moodBefore = ''
  form.isSuccess = 1
  showDialog.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitLoading.value = true
  try {
    await saveBehavior({
      interveneType: form.interveneType,
      moodBefore: form.moodBefore,
      isSuccess: form.isSuccess,
      interveneTime: dayjs().format('YYYY-MM-DDTHH:mm:ss')
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
  margin-bottom: 16px;
}
.stat-card {
  text-align: center;
}
.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
}
.stat-label {
  font-size: 14px;
}
.section-card {
  margin-bottom: 16px;
}
</style>
