import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/login', name: 'Login', component: () => import('@/views/login/index.vue'), meta: { title: '登录' } },
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', name: 'Dashboard', component: () => import('@/views/dashboard/index.vue'), meta: { title: '数据控制台' } },
  { path: '/goal', name: 'Goal', component: () => import('@/views/goal/index.vue'), meta: { title: '目标管理' } },
  { path: '/data', name: 'Data', component: () => import('@/views/data/index.vue'), meta: { title: '数据大屏' } },
  { path: '/behavior', name: 'Behavior', component: () => import('@/views/behavior/index.vue'), meta: { title: '行为矫正' } },
  { path: '/finance', name: 'Finance', component: () => import('@/views/finance/index.vue'), meta: { title: '财务行动' } },
  { path: '/study', name: 'Study', component: () => import('@/views/study/index.vue'), meta: { title: '学习中心' } },
  { path: '/sideline', name: 'Sideline', component: () => import('@/views/sideline/index.vue'), meta: { title: '副业落地' } },
  { path: '/reading', name: 'Reading', component: () => import('@/views/reading/index.vue'), meta: { title: '读书阅读' } },
  { path: '/leisure', name: 'Leisure', component: () => import('@/views/leisure/index.vue'), meta: { title: '生活丰盈' } },
  { path: '/elite', name: 'Elite', component: () => import('@/views/elite/index.vue'), meta: { title: '精英对标' } },
  { path: '/report', name: 'Report', component: () => import('@/views/report/index.vue'), meta: { title: 'AI复盘' } },
  { path: '/setting', name: 'Setting', component: () => import('@/views/setting/index.vue'), meta: { title: '个人设置' } }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  if (to.path !== '/login' && !token) {
    next('/login')
  } else {
    next()
  }
})

export default router
