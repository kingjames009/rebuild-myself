<template>
  <el-container style="height: 100vh">
    <el-aside width="220px" style="background: #2C3E50">
      <div class="logo">日新</div>
      <el-menu
        :default-active="activeMenu"
        background-color="#2C3E50"
        text-color="#B0BEC5"
        active-text-color="#FFFFFF"
        router
        style="border-right: none"
      >
        <el-menu-item index="/dashboard">
          <el-icon><DataBoard /></el-icon><span>数据控制台</span>
        </el-menu-item>
        <el-menu-item index="/goal">
          <el-icon><Flag /></el-icon><span>目标管理</span>
        </el-menu-item>
        <el-menu-item index="/data">
          <el-icon><PieChart /></el-icon><span>数据大屏</span>
        </el-menu-item>
        <el-menu-item index="/behavior">
          <el-icon><MagicStick /></el-icon><span>行为矫正</span>
        </el-menu-item>
        <el-menu-item index="/finance">
          <el-icon><Money /></el-icon><span>财务行动</span>
        </el-menu-item>
        <el-menu-item index="/study">
          <el-icon><Notebook /></el-icon><span>学习中心</span>
        </el-menu-item>
        <el-menu-item index="/sideline">
          <el-icon><TrendCharts /></el-icon><span>副业落地</span>
        </el-menu-item>
        <el-menu-item index="/reading">
          <el-icon><Reading /></el-icon><span>读书阅读</span>
        </el-menu-item>
        <el-menu-item index="/leisure">
          <el-icon><Sunny /></el-icon><span>生活丰盈</span>
        </el-menu-item>
        <el-menu-item index="/elite">
          <el-icon><Star /></el-icon><span>精英对标</span>
        </el-menu-item>
        <el-menu-item index="/report">
          <el-icon><Document /></el-icon><span>AI复盘</span>
        </el-menu-item>
        <el-menu-item index="/setting">
          <el-icon><Setting /></el-icon><span>个人设置</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header style="background: #fff; border-bottom: 1px solid #EBEEF5; display: flex; align-items: center; justify-content: flex-end; padding: 0 20px">
        <span style="margin-right: 16px; color: #666">{{ nickname }}</span>
        <el-button type="danger" link @click="handleLogout">退出</el-button>
      </el-header>
      <el-main style="background: #F5F7FA">
        <slot />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/store/user'

const route = useRoute()
const router = useRouter()
const store = useUserStore()

const activeMenu = computed(() => route.path)
const nickname = computed(() => store.nickname)

const handleLogout = () => store.logout()
</script>

<style scoped>
.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 20px;
  font-weight: 600;
  letter-spacing: 4px;
  border-bottom: 1px solid rgba(255,255,255,0.1);
}
</style>
