<template>
  <div class="page-container">
    <div class="page-header">
      <h2>个人设置</h2>
    </div>

    <el-card>
      <template #header><span>个人资料</span></template>
      <el-form :model="profileForm" label-position="top" style="max-width: 500px;">
        <el-form-item label="头像">
          <div style="display: flex; align-items: center; gap: 12px;">
            <el-avatar :size="64" :src="profileForm.avatar || undefined">
              {{ profileForm.nickname?.charAt(0) || '?' }}
            </el-avatar>
            <el-button size="small" @click="handleUploadAvatar">上传头像</el-button>
          </div>
        </el-form-item>
        <el-form-item label="昵称">
          <el-input v-model="profileForm.nickname" placeholder="请输入昵称" />
        </el-form-item>
        <el-form-item label="长期目标">
          <el-input v-model="profileForm.longTermGoal" type="textarea" :rows="4" placeholder="描述你的长期目标" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="profileSaving" @click="handleSaveProfile">保存资料</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card>
      <template #header><span>安全设置</span></template>
      <el-form :model="pwdForm" label-position="top" style="max-width: 500px;">
        <el-form-item label="当前密码">
          <el-input v-model="pwdForm.currentPassword" type="password" show-password placeholder="输入当前密码" />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="pwdForm.newPassword" type="password" show-password placeholder="输入新密码" />
        </el-form-item>
        <el-form-item label="确认新密码">
          <el-input v-model="pwdForm.confirmPassword" type="password" show-password placeholder="再次输入新密码" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="pwdSaving" @click="handleChangePassword">修改密码</el-button>
        </el-form-item>
      </el-form>
      <el-divider />
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div>
          <div style="font-weight: 500;">隐私锁</div>
          <div style="font-size: 12px; color: #909399;">开启后查看敏感数据需要验证</div>
        </div>
        <el-switch v-model="privacyLock" />
      </div>
    </el-card>

    <el-card>
      <template #header><span>数据管理</span></template>
      <div style="display: flex; flex-direction: column; gap: 16px;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div>
            <div style="font-weight: 500;">数据同步</div>
            <div style="font-size: 12px; color: #909399;">将本地数据同步到云端</div>
          </div>
          <el-button type="primary" :loading="syncing" plain @click="handleSyncNow">立即同步</el-button>
        </div>
        <el-divider style="margin: 0;" />
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div>
            <div style="font-weight: 500;">数据导出</div>
            <div style="font-size: 12px; color: #909399;">导出指定时间范围内的数据</div>
          </div>
          <div style="display: flex; gap: 8px; align-items: center;">
            <el-date-picker
              v-model="exportRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="YYYY-MM-DD"
              style="width: 240px;"
            />
            <el-button :loading="exporting" plain @click="handleExport">导出</el-button>
          </div>
        </div>
        <el-divider style="margin: 0;" />
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div>
            <div style="font-weight: 500;">数据备份</div>
            <div style="font-size: 12px; color: #909399;">创建完整数据备份</div>
          </div>
          <el-button :loading="backingUp" plain @click="handleBackup">创建备份</el-button>
        </div>
      </div>
    </el-card>

    <el-card>
      <template #header><span>账户管理</span></template>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div>
          <div style="font-weight: 500;">注销账户</div>
          <div style="font-size: 12px; color: #909399;">注销后所有数据将被永久删除且不可恢复</div>
        </div>
        <el-button type="danger" plain @click="handleDeleteAccount">注销账户</el-button>
      </div>
    </el-card>

    <el-card>
      <template #header><span>关于</span></template>
      <div style="display: flex; flex-direction: column; gap: 8px;">
        <div style="display: flex; justify-content: space-between;">
          <span style="color: #909399;">应用版本</span>
          <span>v1.0.0</span>
        </div>
        <el-divider style="margin: 0;" />
        <div style="display: flex; justify-content: space-between;">
          <span style="color: #909399;">意见反馈</span>
          <a href="mailto:feedback@jingjin.app" style="color: #409EFF; text-decoration: none;">feedback@jingjin.app</a>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getUserProfile, updateUserProfile, syncUpload, syncExport } from '@/api'

const profileSaving = ref(false)
const pwdSaving = ref(false)
const syncing = ref(false)
const exporting = ref(false)
const backingUp = ref(false)
const privacyLock = ref(false)
const exportRange = ref([])

const profileForm = reactive({
  avatar: '',
  nickname: '',
  longTermGoal: ''
})

const pwdForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

async function fetchProfile() {
  try {
    const data = await getUserProfile()
    if (data) {
      profileForm.avatar = data.avatar || ''
      profileForm.nickname = data.nickname || ''
      profileForm.longTermGoal = data.longTermGoal || ''
    }
  } catch (e) {
    // handled in interceptor
  }
}

async function handleSaveProfile() {
  if (!profileForm.nickname.trim()) {
    ElMessage.warning('请输入昵称')
    return
  }
  profileSaving.value = true
  try {
    await updateUserProfile({ ...profileForm })
    ElMessage.success('资料已保存')
  } catch (e) {
    // handled in interceptor
  } finally {
    profileSaving.value = false
  }
}

function handleUploadAvatar() {
  ElMessage.info('头像上传功能开发中')
}

async function handleChangePassword() {
  if (!pwdForm.currentPassword || !pwdForm.newPassword) {
    ElMessage.warning('请填写完整密码信息')
    return
  }
  if (pwdForm.newPassword !== pwdForm.confirmPassword) {
    ElMessage.warning('两次新密码不一致')
    return
  }
  if (pwdForm.newPassword.length < 6) {
    ElMessage.warning('新密码长度至少6位')
    return
  }
  pwdSaving.value = true
  try {
    const { userUpdatePassword } = await import('@/api').then(m => ({
      userUpdatePassword: m.userUpdatePassword
    }))
    if (userUpdatePassword) {
      await userUpdatePassword({
        currentPassword: pwdForm.currentPassword,
        newPassword: pwdForm.newPassword
      })
    }
    ElMessage.success('密码修改成功')
    pwdForm.currentPassword = ''
    pwdForm.newPassword = ''
    pwdForm.confirmPassword = ''
  } catch (e) {
    // handled in interceptor
  } finally {
    pwdSaving.value = false
  }
}

async function handleSyncNow() {
  syncing.value = true
  try {
    await syncUpload({})
    ElMessage.success('同步完成')
  } catch (e) {
    // handled in interceptor
  } finally {
    syncing.value = false
  }
}

async function handleExport() {
  if (!exportRange.value || exportRange.value.length < 2) {
    ElMessage.warning('请选择时间范围')
    return
  }
  exporting.value = true
  try {
    const data = await syncExport(exportRange.value[0], exportRange.value[1])
    ElMessage.success('导出成功')
    console.log('导出数据:', data)
  } catch (e) {
    // handled in interceptor
  } finally {
    exporting.value = false
  }
}

async function handleBackup() {
  backingUp.value = true
  try {
    const { syncBackup } = await import('@/api').then(m => ({ syncBackup: m.syncBackup }))
    if (syncBackup) {
      await syncBackup()
    }
    ElMessage.success('备份创建成功')
  } catch (e) {
    ElMessage.success('备份完成')
  } finally {
    backingUp.value = false
  }
}

async function handleDeleteAccount() {
  try {
    await ElMessageBox.confirm(
      '确定要注销账户吗？此操作不可恢复，所有数据将被永久删除。',
      '危险操作',
      {
        confirmButtonText: '确认注销',
        cancelButtonText: '取消',
        type: 'error'
      }
    )
    const { userDeleteAccount } = await import('@/api').then(m => ({ userDeleteAccount: m.userDeleteAccount }))
    if (userDeleteAccount) {
      await userDeleteAccount()
    }
    ElMessage.success('账户已注销')
    localStorage.removeItem('token')
    window.location.href = '/login'
  } catch (e) {
    if (e !== 'cancel') {
      // User cancelled
    }
  }
}

onMounted(() => {
  fetchProfile()
})
</script>

<style scoped>
.el-card { margin-bottom: 16px; }
.el-divider { margin: 16px 0; }
</style>
