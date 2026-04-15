<template>
  <div class="login-container">
    <el-card class="login-card">
      <div slot="header" class="login-header">
        <h2>测试资产库系统</h2>
        <p>请登录您的账号</p>
      </div>
      <el-form :model="loginForm" :rules="loginRules" ref="loginForm" @submit.native.prevent="handleLogin">
        <el-form-item prop="username">
          <el-input 
            v-model="loginForm.username" 
            placeholder="用户名：员工号" 
            prefix-icon="el-icon-user">
          </el-input>
        </el-form-item>
        <el-form-item prop="password">
          <el-input 
            v-model="loginForm.password" 
            type="password" 
            placeholder="默认密码：ILike88Door" 
            prefix-icon="el-icon-lock"
            show-password>
          </el-input>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" native-type="submit" :loading="loading" class="login-button">登 录</el-button>
        </el-form-item>
      </el-form>
      <div class="login-tips">
        <p>* 外购人员登录需校验密码</p>
        <p>* 内部人员根据系统配置决定是否校验密码</p>
      </div>
    </el-card>
  </div>
</template>

<script>
import { login } from '@/api/user'
import { aesEncrypt, md5Encrypt } from '@/utils/crypto'

export default {
  name: 'Login',
  data() {
    return {
      loginForm: {
        username: '',
        password: ''
      },
      loginRules: {
        username: [{ required: true, message: '请输入用户名', trigger: 'blur' }]
      },
      loading: false
    }
  },
  mounted() {
    const { t_u, t_p } = this.$route.query
    if (t_u && t_p) {
      this.autoLogin(t_u, t_p)
    }
  },
  methods: {
    async autoLogin(username, md5Password) {
      this.loading = true
      try {
        const res = await login({
          username: username,
          password: '', // 自动登录无法提供 AES 密文
          md5Password: md5Password
        })

        // 存储登录信息
        localStorage.setItem('token', res.token)
        localStorage.setItem('userId', res.user.id)
        localStorage.setItem('userInfo', JSON.stringify(res.user))

        this.$message.success('自动登录成功')
        this.$router.push('/')
      } catch (error) {
        console.error('Auto login failed:', error)
        // 自动登录失败不弹窗，让用户手动登录即可
      } finally {
        this.loading = false
      }
    },
    async handleLogin() {
      this.$refs.loginForm.validate(async (valid) => {
        if (valid) {
          this.loading = true
          try {
            // 同时生成 AES 和 MD5 密文
            const aesPassword = aesEncrypt(this.loginForm.password)
            const md5Password = md5Encrypt(this.loginForm.password)
            
            const res = await login({
              username: this.loginForm.username,
              password: aesPassword, // 后端接收 password 字段作为 AES 密文
              md5Password: md5Password
            })

            
            // 存储登录信息
            localStorage.setItem('token', res.token)
            localStorage.setItem('userId', res.user.id)
            localStorage.setItem('userInfo', JSON.stringify(res.user))
            
            this.$message.success('登录成功')
            this.$router.push('/')
          } catch (error) {
            console.error('Login failed:', error)
          } finally {
            this.loading = false
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.login-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #f5f7fa;
  background-image: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
}

.login-card {
  width: 400px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.login-header {
  text-align: center;
}

.login-header h2 {
  margin: 0;
  color: #409EFF;
  font-size: 24px;
}

.login-header p {
  margin: 10px 0 0;
  color: #909399;
  font-size: 14px;
}

.login-button {
  width: 100%;
  height: 40px;
  font-size: 16px;
}

.login-tips {
  margin-top: 20px;
  padding-top: 15px;
  border-top: 1px dashed #ebeef5;
  font-size: 12px;
  color: #909399;
}

.login-tips p {
  margin: 5px 0;
}
</style>
