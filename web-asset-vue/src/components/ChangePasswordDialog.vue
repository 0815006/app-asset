<template>
  <el-dialog
    title="修改密码"
    :visible.sync="dialogVisible"
    width="30%"
    :before-close="handleClose"
  >
    <el-form
      :model="passwordForm"
      :rules="passwordRules"
      ref="passwordForm"
      label-width="100px"
    >
      <el-form-item label="旧密码" prop="oldPassword">
        <el-input type="password" v-model="passwordForm.oldPassword" autocomplete="off" show-password></el-input>
      </el-form-item>
      <el-form-item label="新密码" prop="newPassword">
        <el-input type="password" v-model="passwordForm.newPassword" autocomplete="off" show-password></el-input>
      </el-form-item>
      <el-form-item label="确认新密码" prop="confirmPassword">
        <el-input type="password" v-model="passwordForm.confirmPassword" autocomplete="off" show-password></el-input>
      </el-form-item>
    </el-form>
    <span slot="footer" class="dialog-footer">
      <el-button @click="handleClose">取 消</el-button>
      <el-button type="primary" @click="submitForm('passwordForm')">确 定</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { changePassword } from '@/api/user'; // Import the API function

export default {
  name: 'ChangePasswordDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    const validatePass = (rule, value, callback) => {
      if (value === '') {
        callback(new Error('请输入新密码'));
      } else if (value.length < 6) {
        callback(new Error('密码长度不能少于6位'));
      } else {
        if (this.passwordForm.confirmPassword !== '') {
          this.$refs.passwordForm.validateField('confirmPassword');
        }
        callback();
      }
    };
    const validatePass2 = (rule, value, callback) => {
      if (value === '') {
        callback(new Error('请再次输入新密码'));
      } else if (value !== this.passwordForm.newPassword) {
        callback(new Error('两次输入密码不一致!'));
      } else {
        callback();
      }
    };
    return {
      dialogVisible: this.visible,
      passwordForm: {
        oldPassword: '',
        newPassword: '',
        confirmPassword: ''
      },
      passwordRules: {
        oldPassword: [
          { required: true, message: '请输入旧密码', trigger: 'blur' }
        ],
        newPassword: [
          { required: true, validator: validatePass, trigger: 'blur' }
        ],
        confirmPassword: [
          { required: true, validator: validatePass2, trigger: 'blur' }
        ]
      }
    };
  },
  watch: {
    visible(newVal) {
      this.dialogVisible = newVal;
      if (newVal) {
        this.$nextTick(() => {
          this.$refs.passwordForm.resetFields();
        });
      }
    }
  },
  methods: {
    handleClose() {
      this.dialogVisible = false;
      this.$emit('update:visible', false);
      this.$refs.passwordForm.resetFields();
    },
    submitForm(formName) {
      this.$refs[formName].validate(valid => {
        if (valid) {
          const { oldPassword, newPassword } = this.passwordForm;
          changePassword({ oldPassword, newPassword }).then(() => {
            this.$message.success('密码修改成功，请重新登录');
            this.handleClose();
            // 清除登录信息并跳转到登录页
            localStorage.removeItem('token');
            localStorage.removeItem('userId');
            localStorage.removeItem('userInfo');
            this.$router.push('/login');
          }).catch(error => {
            // request.js already shows a message for non-200 codes, 
            // but we can add extra context here if needed.
            console.error('Password change failed:', error);
          });
        } else {
          this.$message.error('表单验证失败');
          return false;
        }
      });
    }
  }
};
</script>

<style scoped>
/* Add any specific styles for the dialog here */
</style>
