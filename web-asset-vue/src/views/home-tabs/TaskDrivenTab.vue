<template>
  <div class="tab-content">
    <el-row :gutter="20">
      <el-col :span="12">
        <el-card class="workspace-card">
          <div slot="header" class="card-header">
            <span><i class="el-icon-star-on"></i> 我的收藏</span>
          </div>
          <my-star-list @node-click="handleSearchResultClick"></my-star-list>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card class="workspace-card">
          <div slot="header" class="card-header">
            <span><i class="el-icon-time"></i> 最近访问</span>
          </div>
          <recent-access-list :recent-files="recentFiles" @node-click="handleSearchResultClick"></recent-access-list>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import MyStarList from "../../components/MyStarList.vue";
import RecentAccessList from "../../components/RecentAccessList.vue";
import { getRecentAccessedFiles } from "@/api/asset-node";

export default {
  name: "TaskDrivenTab",
  components: {
    MyStarList,
    RecentAccessList,
  },
  data() {
    return {
      recentFiles: [],
      currentUser: JSON.parse(localStorage.getItem('userInfo') || '{}')
    }
  },
  created() {
    this.fetchRecentAccessedFiles();
  },
  methods: {
    async fetchRecentAccessedFiles() {
      if (!this.currentUser || !this.currentUser.id) {
        return;
      }
      try {
        const res = await getRecentAccessedFiles({ userId: this.currentUser.id });
        this.recentFiles = res || [];
      } catch (error) {
        console.error("Failed to fetch recent accessed files:", error);
        this.$message.error("获取最近访问列表失败");
      }
    },
    handleSearchResultClick(item) {
      this.$emit("node-click", item);
    },
  },
};
</script>

<style scoped>
.tab-content {
  padding: 10px 0;
}

.workspace-card /deep/ .el-card__header {
  font-weight: bold;
  color: #303133;
}
</style>
