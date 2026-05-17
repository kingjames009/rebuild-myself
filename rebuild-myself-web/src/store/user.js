import { defineStore } from 'pinia'
import { getUserProfile, userLogin } from '@/api'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    userInfo: null
  }),
  getters: {
    isLogin: (state) => !!state.token,
    nickname: (state) => state.userInfo?.nickname || '自律用户'
  },
  actions: {
    async login(phone, password) {
      const token = await userLogin({ phone, password })
      this.token = token
      localStorage.setItem('token', token)
      await this.fetchProfile()
    },
    async fetchProfile() {
      try { this.userInfo = await getUserProfile() } catch (e) { /* ignore */ }
    },
    logout() {
      this.token = ''
      this.userInfo = null
      localStorage.removeItem('token')
      window.location.hash = '#/login'
    }
  }
})
