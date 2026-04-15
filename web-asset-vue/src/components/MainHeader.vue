<template>
  <div>
    <div class="top-nav-bar">
      <div :class="['nav-container', { 'is-iframe-mode': isIframe }]">
        <div class="logo-section" @click="goToHome('search-first')">
          <i class="el-icon-s-finance"></i>
          <span class="logo-text">测试资产库</span>
        </div>
        
        <div class="tabs-wrapper">
          <el-tabs v-model="localActiveTab" class="main-tabs" @tab-click="handleTabClick">
            <el-tab-pane label="智能探索" name="search-first"></el-tab-pane>
            <el-tab-pane label="业务版图" name="business-landscape"></el-tab-pane>
            <el-tab-pane label="资产拓扑" name="relationship-graph"></el-tab-pane>
            <el-tab-pane label="测试工作区" name="task-driven"></el-tab-pane>
          </el-tabs>
        </div>
        
        <div v-if="!isIframe" class="user-info-wrapper">
          <el-dropdown @command="handleCommand" trigger="click">
            <div class="user-info-content">
              <el-avatar size="small" icon="el-icon-user-solid"></el-avatar>
              <span class="username">{{ realName }}</span>
              <i class="el-icon-arrow-down el-icon--right"></i>
            </div>
            <el-dropdown-menu slot="dropdown">
              <!-- <el-dropdown-item command="changePassword" icon="el-icon-lock">修改密码</el-dropdown-item> -->
              <el-dropdown-item command="logout" icon="el-icon-switch-button">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </div>
        <!-- iframe 模式下的占位符，用于保持中间菜单居中 -->
        <div v-else class="user-info-placeholder"></div>
      </div>
    </div>
    <change-password-dialog :visible.sync="showChangePasswordDialog"></change-password-dialog>
  </div>
</template>

<script>
import ChangePasswordDialog from './ChangePasswordDialog.vue';

export default {
  name: 'MainHeader',
  components: {
    ChangePasswordDialog
  },
  props: {
    activeTab: {
      type: String,
      default: 'search-first'
    }
  },
  data() {
    return {
      showChangePasswordDialog: false,

    };
  },
  computed: {
    realName() {
      const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}');
      return userInfo.realName || '未登录';
    },
    isIframe() {
      return window.self !== window.top;
    },
    localActiveTab: {
      get() {
        return this.activeTab;
      },
      set(val) {
        this.$emit('update:activeTab', val);
      }
    }
  },
  methods: {
    handleCommand(command) {
      if (command === 'logout') {
        this.handleLogout();
      } else if (command === 'changePassword') {
        this.showChangePasswordDialog = true;
      }
    },
    handleLogout() {
      this.$confirm('确定要退出登录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        localStorage.removeItem('token');
        localStorage.removeItem('userId');
        localStorage.removeItem('userInfo');
        this.$message.success('已退出登录');
        this.$router.push('/login');
      }).catch(() => {});
    },
    handleTabClick(tab) {
      if (this.$route.path !== '/') {
        this.$router.push({ path: '/', query: { tab: tab.name } });
      }
    },
    goToHome(tabName) {
      if (this.$route.path !== '/') {
        this.$router.push({ path: '/', query: { tab: tabName } });
      } else {
        this.localActiveTab = tabName;
      }
    }
  }
}
</script>

<style scoped>
.top-nav-bar {
  background-color: #fff;
  border-bottom: 1px solid #ebeef5;
  position: sticky;
  top: 0;
  z-index: 100;
  height: 60px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

.nav-container {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
  padding: 0 20px;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #409EFF;
  font-weight: bold;
  font-size: 18px;
  width: 150px;
  cursor: pointer;
}

.tabs-wrapper {
  flex: 1;
  display: flex;
  justify-content: center;
  height: 100%;
}

.main-tabs {
  height: 100%;
}

.main-tabs /deep/ .el-tabs__header {
  margin: 0;
  border-bottom: none;
  background: transparent;
}

.main-tabs /deep/ .el-tabs__nav-wrap::after {
  display: none;
}

.main-tabs /deep/ .el-tabs__nav-scroll {
  display: flex;
  justify-content: center;
}

.main-tabs /deep/ .el-tabs__item {
  height: 60px;
  line-height: 60px;
  font-size: 16px;
  font-weight: bold;
  color: #606266;
  padding: 0 25px;
}

.main-tabs /deep/ .el-tabs__item.is-active {
  color: #409EFF;
}

.user-info-wrapper {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #606266;
  font-size: 14px;
  cursor: pointer;
  width: 150px;
  justify-content: flex-end;
}

.username {
  font-weight: 500;
}

.user-info-content {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.user-info-content:hover .username {
  color: #409EFF;
}

/* iframe 模式优化 */
.nav-container.is-iframe-mode {
  max-width: 100%;
  padding: 0 15px;
}

.user-info-placeholder {
  width: 150px; /* 与 logo-section 宽度一致，确保中间 tabs 居中 */
}
</style>