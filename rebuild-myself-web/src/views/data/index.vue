<template>
  <div class="page-container">
    <div class="page-header">
      <h2>数据大屏</h2>
      <div class="header-actions">
        <el-select v-model="recordType" placeholder="记录类型" clearable style="width:140px;margin-right:12px" @change="fetchData">
          <el-option label="全部" value="" />
          <el-option label="学习" value="study" />
          <el-option label="工作" value="work" />
          <el-option label="生活" value="life" />
          <el-option label="运动" value="sport" />
          <el-option label="其它" value="other" />
        </el-select>
        <el-date-picker
          v-model="dateRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          value-format="YYYY-MM-DD"
          @change="fetchData"
        />
      </div>
    </div>

    <!-- Section 1: Daily Records Breakdown -->
    <el-card class="section-card">
      <template #header><span>每日记录明细</span></template>
      <el-table :data="recordList" stripe v-loading="recordLoading" empty-text="暂无记录">
        <el-table-column prop="date" label="日期" width="120" sortable />
        <el-table-column prop="type" label="类型" width="120">
          <template #default="{ row }">
            <el-tag :type="typeTag(row.type)" size="small">{{ typeLabel(row.type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="内容" min-width="200" show-overflow-tooltip />
        <el-table-column label="情绪评分" width="120">
          <template #default="{ row }">
            <el-rate v-if="row.moodScore" v-model="row.moodScore" disabled size="small" />
            <span v-else style="color:#999">--</span>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-if="recordTotal > 0"
        v-model:current-page="recordPage"
        :page-size="recordSize"
        :total="recordTotal"
        layout="prev, pager, next"
        class="pagination"
        @current-change="fetchRecords"
      />
    </el-card>

    <!-- Section 2: Emotion Score Trend -->
    <el-card class="section-card">
      <template #header><span>情绪评分趋势</span></template>
      <div v-if="emotionData.length === 0" style="text-align:center;padding:40px 0;color:#999">
        <el-empty description="暂无情绪数据" />
      </div>
      <div v-else style="height:300px">
        <div style="display:flex;align-items:flex-end;gap:12px;height:260px;padding:0 20px">
          <div
            v-for="(item, idx) in emotionData"
            :key="idx"
            style="flex:1;display:flex;flex-direction:column;align-items:center;"
          >
            <div
              :style="{
                height: (item.avgScore / 5) * 220 + 'px',
                width: '100%',
                maxWidth: '40px',
                background: emotionBarColor(item.avgScore),
                borderRadius: '4px 4px 0 0',
                transition: 'height 0.3s',
                display: 'flex',
                alignItems: 'flex-start',
                justifyContent: 'center',
                paddingTop: '4px',
                fontSize: '11px',
                color: '#fff'
              }"
            >
              {{ item.avgScore }}
            </div>
            <span style="font-size:11px;color:#909399;margin-top:6px;writing-mode:vertical-lr;text-orientation:mixed;height:50px">
              {{ item.date }}
            </span>
          </div>
        </div>
      </div>
    </el-card>

    <!-- Section 3: Record Type Distribution -->
    <el-card class="section-card">
      <template #header><span>记录类型分布</span></template>
      <div v-if="typeStats.length === 0" style="text-align:center;padding:20px 0;color:#999">
        <el-empty description="暂无统计数据" />
      </div>
      <div v-else>
        <div v-for="item in typeStats" :key="item.type" style="margin-bottom:16px">
          <div style="display:flex;justify-content:space-between;margin-bottom:4px">
            <span>{{ typeLabel(item.type) }}</span>
            <span>{{ item.count }} 条 ({{ item.percent }}%)</span>
          </div>
          <el-progress
            :percentage="item.percent"
            :color="typeColor(item.type)"
            :stroke-width="20"
            :format="() => ''"
          />
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getRecordPage, getRecordStats } from '@/api'
import dayjs from 'dayjs'

const dateRange = ref([
  dayjs().subtract(7, 'day').format('YYYY-MM-DD'),
  dayjs().format('YYYY-MM-DD')
])
const recordType = ref('')

// Record table
const recordList = ref([])
const recordLoading = ref(false)
const recordPage = ref(1)
const recordSize = ref(10)
const recordTotal = ref(0)

// Emotion data
const emotionData = ref([])

// Type stats
const typeStats = ref([])

const typeMap = {
  study: '学习',
  work: '工作',
  life: '生活',
  sport: '运动',
  other: '其它'
}

const typeTag = (t) => {
  const map = { study: 'primary', work: 'success', life: 'warning', sport: 'danger' }
  return map[t] || 'info'
}

const typeLabel = (t) => typeMap[t] || t

const typeColor = (t) => {
  const map = { study: '#409EFF', work: '#67C23A', life: '#E6A23C', sport: '#F56C6C' }
  return map[t] || '#909399'
}

const emotionBarColor = (score) => {
  if (score >= 4) return '#67C23A'
  if (score >= 3) return '#409EFF'
  if (score >= 2) return '#E6A23C'
  return '#F56C6C'
}

const fetchRecords = async () => {
  recordLoading.value = true
  try {
    const res = await getRecordPage(recordPage.value, recordSize.value, recordType.value || undefined)
    recordList.value = res.records || []
    recordTotal.value = res.total || 0
  } catch (e) {
    // handled
  } finally {
    recordLoading.value = false
  }
}

const fetchStats = async () => {
  try {
    const [start, end] = dateRange.value || []
    if (!start || !end) return
    const res = await getRecordStats(start, end)
    emotionData.value = res.emotionTrend || []
    typeStats.value = res.typeDistribution || []
  } catch (e) {
    // handled
  }
}

const fetchData = () => {
  fetchRecords()
  fetchStats()
}

onMounted(fetchData)
</script>

<style scoped>
.section-card {
  margin-bottom: 16px;
}
.pagination {
  margin-top: 16px;
  justify-content: center;
}
.header-actions {
  display: flex;
  align-items: center;
}
</style>
