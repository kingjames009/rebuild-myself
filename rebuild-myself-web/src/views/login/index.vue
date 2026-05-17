<template>
  <div class="login-page">
    <el-card class="login-card" shadow="always">
      <div class="login-header">
        <h1 class="app-name">日新</h1>
        <p class="app-subtitle">全维度人生重塑自律成长</p>
      </div>
      <el-tabs v-model="activeTab" stretch>
        <el-tab-pane label="登录" name="login">
          <el-form ref="loginFormRef" :model="loginForm" :rules="loginRules" label-width="0">
            <el-form-item prop="phone">
              <el-input v-model="loginForm.phone" placeholder="手机号" size="large" :prefix-icon="Iphone" />
            </el-form-item>
            <el-form-item prop="password">
              <el-input v-model="loginForm.password" type="password" placeholder="密码" size="large" show-password :prefix-icon="Lock" @keyup.enter="handleLogin" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" size="large" :loading="loginLoading" class="submit-btn" @click="handleLogin">登录</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>
        <el-tab-pane label="注册" name="register">
          <el-form ref="registerFormRef" :model="registerForm" :rules="registerRules" label-width="0">
            <el-form-item prop="phone">
              <el-input v-model="registerForm.phone" placeholder="手机号" size="large" :prefix-icon="Iphone" />
            </el-form-item>
            <el-form-item prop="password">
              <el-input v-model="registerForm.password" type="password" placeholder="密码" size="large" show-password :prefix-icon="Lock" />
            </el-form-item>
            <el-form-item prop="confirmPassword">
              <el-input v-model="registerForm.confirmPassword" type="password" placeholder="确认密码" size="large" show-password :prefix-icon="Lock" @keyup.enter="handleRegister" />
            </el-form-item>
            <el-form-item>
              <el-button type="success" size="large" :loading="registerLoading" class="submit-btn" @click="handleRegister">注册</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, shallowRef } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Iphone, Lock } from '@element-plus/icons-vue'
import { userLogin, userRegister } from '@/api'
import { useUserStore } from '@/store/user'

const router = useRouter()
const userStore = useUserStore()

const activeTab = ref('login')
const loginLoading = ref(false)
const registerLoading = ref(false)
const loginFormRef = ref(null)
const registerFormRef = ref(null)

const loginForm = reactive({
  phone: '',
  password: ''
})

const registerForm = reactive({
  phone: '',
  password: '',
  confirmPassword: ''
})

const validatePhone = (rule, value, callback) => {
  if (!/^1[3-9]\d{9}$/.test(value)) {
    callback(new Error('请输入正确的手机号'))
  } else {
    callback()
  }
}

const loginRules = {
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { validator: validatePhone, trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 32, message: '密码长度为6-32位', trigger: 'blur' }
  ]
}

const registerRules = {
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { validator: validatePhone, trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 32, message: '密码长度为6-32位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== registerForm.password) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

const handleLogin = async () => {
  const valid = await loginFormRef.value.validate().catch(() => false)
  if (!valid) return
  loginLoading.value = true
  try {
    await userStore.login(loginForm.phone, loginForm.password)
    ElMessage.success('登录成功')
    router.push('/dashboard')
  } catch (e) {
    // message already handled in interceptor
  } finally {
    loginLoading.value = false
  }
}

const handleRegister = async () => {
  const valid = await registerFormRef.value.validate().catch(() => false)
  if (!valid) return
  registerLoading.value = true
  try {
    await userRegister({
      phone: registerForm.phone,
      password: registerForm.password
    })
    ElMessage.success('注册成功，请登录')
    activeTab.value = 'login'
    loginForm.phone = registerForm.phone
  } catch (e) {
    // handled in interceptor
  } finally {
    registerLoading.value = false
  }
}
</script>

<style scoped>
.login-page {
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
.login-card {
  width: 420px;
  border-radius: 12px;
}
.login-header {
  text-align: center;
  margin-bottom: 24px;
}
.app-name {
  font-size: 32px;
  font-weight: 700;
  color: #303133;
  letter-spacing: 6px;
  margin: 0;
}
.app-subtitle {
  font-size: 14px;
  color: #909399;
  margin: 8px 0 0 0;
}
.submit-btn {
  width: 100%;
}
</style>
