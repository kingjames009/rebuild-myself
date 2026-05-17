<template>
  <div class="page-container">
    <div class="page-header">
      <h2>生活丰盈</h2>
    </div>

    <el-card>
      <div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 8px;">
        <el-check-tag
          v-for="chip in typeChips"
          :key="chip.value"
          :checked="activeTypes.includes(chip.value)"
          @change="toggleType(chip.value)"
          style="margin-right: 0;"
        >
          {{ chip.label }}
        </el-check-tag>
      </div>
    </el-card>

    <el-card>
      <template #header><span>快乐指数趋势</span></template>
      <div v-if="trendData.length === 0" style="color: #999; padding: 20px 0; text-align: center;">暂无数据</div>
      <div v-else style="display: flex; align-items: flex-end; gap: 6px; height: 160px; padding: 16px 0;">
        <div
          v-for="(item, index) in trendData"
          :key="index"
          style="flex: 1; display: flex; flex-direction: column; align-items: center;"
        >
          <span style="font-size: 11px; color: #999; margin-bottom: 4px;">{{ item.score }}</span>
          <div
            :style="{
              height: (item.score / 10) * 120 + 'px',
              width: '100%',
              maxWidth: '40px',
              background: item.score >= 7 ? '#67C23A' : item.score >= 4 ? '#E6A23C' : '#F56C6C',
              borderRadius: '4px 4px 0 0',
              transition: 'height 0.3s'
            }"
          />
          <span style="font-size: 10px; color: #ccc; margin-top: 4px; writing-mode: vertical-lr; font-size: 10px;">{{ item.date }}</span>
        </div>
      </div>
    </el-card>

    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>休闲记录</span>
          <el-button type="primary" size="small" @click="openAddDialog">新增记录</el-button>
        </div>
      </template>
      <el-table :data="records" stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="tagType(row.type)" size="small">{{ typeLabel(row.type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="minutes" label="时长(分钟)" width="100" align="center" />
        <el-table-column prop="happyScore" label="快乐指数" width="140" align="center">
          <template #default="{ row }">
            <el-rate v-model="row.happyScore" disabled :max="10" />
          </template>
        </el-table-column>
        <el-table-column prop="date" label="日期" width="100" />
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

    <el-card>
      <template #header><span>休闲灵感建议</span></template>
      <el-row :gutter="16">
        <el-col :span="8" v-for="(suggestion, index) in suggestions" :key="index" style="margin-bottom: 12px;">
          <el-tag :type="suggestion.tag" style="margin-bottom: 4px;">{{ suggestion.type }}</el-tag>
          <p style="font-size: 13px; color: #606266; margin: 4px 0 0 0;">{{ suggestion.text }}</p>
        </el-col>
      </el-row>
    </el-card>

    <el-dialog v-model="dialogVisible" title="新增休闲记录" width="480px">
      <el-form :model="form" label-position="top">
        <el-form-item label="类型">
          <el-select v-model="form.type" style="width: 100%;">
            <el-option v-for="chip in typeChips" :key="chip.value" :label="chip.label" :value="chip.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="时长(分钟)">
          <el-input-number v-model="form.minutes" :min="0" :max="600" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="快乐指数">
          <el-slider v-model="form.happyScore" :min="0" :max="10" :step="1" show-input />
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
import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { getLeisurePage, getLeisureTrend, saveLeisure } from '@/api'

const typeChips = [
  { value: 'relax', label: '放松' },
  { value: 'meditation', label: '冥想' },
  { value: 'healing', label: '治愈短句' },
  { value: 'stretch', label: '拉伸' },
  { value: 'organize', label: '环境整理' },
  { value: 'knowledge', label: '碎片新知' }
]

const activeTypes = ref(typeChips.map(c => c.value))
const loading = ref(false)
const saving = ref(false)
const records = ref([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
const trendData = ref([])
const dialogVisible = ref(false)

const form = reactive({
  type: 'relax',
  minutes: 0,
  happyScore: 5
})

const tagColorMap = {
  relax: '',
  meditation: 'success',
  healing: 'warning',
  stretch: 'danger',
  organize: 'info',
  knowledge: ''
}

function typeLabel(type) {
  const chip = typeChips.find(c => c.value === type)
  return chip ? chip.label : type
}

function tagType(type) {
  return tagColorMap[type] || ''
}

function toggleType(value) {
  const idx = activeTypes.value.indexOf(value)
  if (idx >= 0) {
    if (activeTypes.value.length > 1) activeTypes.value.splice(idx, 1)
  } else {
    activeTypes.value.push(value)
  }
  page.value = 1
  fetchRecords()
}

async function fetchTrend() {
  try {
    const data = await getLeisureTrend()
    if (data) trendData.value = data
  } catch (e) {
    // handled in interceptor
  }
}

async function fetchRecords() {
  loading.value = true
  try {
    const data = await getLeisurePage(page.value, size.value)
    if (data) {
      records.value = (data.records || data.list || []).filter(
        r => activeTypes.value.includes(r.type)
      )
      total.value = data.total || 0
    }
  } catch (e) {
    // handled in interceptor
  } finally {
    loading.value = false
  }
}

const suggestions = [
  { type: '放松', tag: '', text: '听一首喜欢的歌，闭眼深呼吸5分钟' },
  { type: '放松', tag: '', text: '看一集20分钟的搞笑短剧，开怀大笑' },
  { type: '冥想', tag: 'success', text: '正念冥想10分钟，关注当下呼吸' },
  { type: '冥想', tag: 'success', text: '身体扫描冥想，从头到脚放松每个部位' },
  { type: '治愈短句', tag: 'warning', text: '写下一件今天让你感到温暖的小事' },
  { type: '治愈短句', tag: 'warning', text: '给一位朋友发一条随机的感谢信息' },
  { type: '拉伸', tag: 'danger', text: '5分钟办公室肩颈拉伸' },
  { type: '拉伸', tag: 'danger', text: '10分钟瑜伽猫牛式 + 下犬式' },
  { type: '环境整理', tag: 'info', text: '书桌五分钟整理：清理杂物、擦拭桌面' },
  { type: '环境整理', tag: 'info', text: '断舍离一件不用的物品' },
  { type: '碎片新知', tag: '', text: '阅读一篇感兴趣的科普短文' },
  { type: '碎片新知', tag: '', text: '看一个3分钟的TED演讲' }
]

function openAddDialog() {
  form.type = 'relax'
  form.minutes = 0
  form.happyScore = 5
  dialogVisible.value = true
}

async function handleSave() {
  saving.value = true
  try {
    await saveLeisure({ ...form })
    ElMessage.success('保存成功')
    dialogVisible.value = false
    fetchRecords()
    fetchTrend()
  } catch (e) {
    // handled in interceptor
  } finally {
    saving.value = false
  }
}

fetchTrend()
fetchRecords()
</script>

<style scoped>
.el-card { margin-bottom: 16px; }
</style>
