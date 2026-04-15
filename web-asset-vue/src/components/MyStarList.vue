<template>
  <div class="my-star-list">
    <div v-if="starredFiles.length === 0" class="empty-text">暂无收藏记录</div>
    <ul class="file-list">
      <li v-for="(item, index) in starredFiles" :key="item.id" class="file-item" @click="handleItemClick(item)">
        <div class="file-info">
          <span class="rank-num">{{ index + 1 }}</span>
          <i :class="getIconClass(item)"></i>
          <span class="file-name" :title="item.fileName">{{ item.fileName }}</span>
          <el-tag v-if="item.isPinned" size="mini" type="warning" class="pin-tag">置顶</el-tag>
        </div>
        <div class="actions" @click.stop>
          <el-tooltip :content="item.isPinned ? '取消置顶' : '置顶'" placement="top">
            <el-button type="text" @click="togglePin(item)">
              <i :class="item.isPinned ? 'el-icon-s-flag' : 'el-icon-top'"></i>
            </el-button>
          </el-tooltip>
          <el-tooltip content="取消收藏" placement="top">
            <el-button type="text" class="delete-btn" @click="unstarFile(item)">
              <i class="el-icon-star-on"></i>
            </el-button>
          </el-tooltip>
        </div>
      </li>
    </ul>
  </div>
</template>

<script>
import { getMyStarredFiles, unstarFile as unstarFileApi, pinFile as pinFileApi } from "@/api/asset-node";

export default {
  name: "MyStarList",
  data() {
    return {
      starredFiles: [],
      currentUser: JSON.parse(localStorage.getItem('userInfo') || '{}')
    };
  },
  created() {
    this.fetchMyStarredFiles();
  },
  methods: {
    async fetchMyStarredFiles() {
      try {
        const res = await getMyStarredFiles({ userId: this.currentUser.id, page: 1, size: 20 });
        this.starredFiles = res || [];
      } catch (error) {
        console.error("Failed to fetch starred files:", error);
        this.$message.error("获取我的收藏失败");
      }
    },
    handleItemClick(item) {
      this.$emit("node-click", item);
    },
    async togglePin(item) {
      try {
        await pinFileApi(item.id, { userId: this.currentUser.id, pin: !item.isPinned });
        this.$message.success(item.isPinned ? "已取消置顶" : "置顶成功");
        this.fetchMyStarredFiles();
      } catch (error) {
        console.error("Failed to toggle pin status:", error);
        this.$message.error("置顶操作失败");
      }
    },
    async unstarFile(item) {
      try {
        await unstarFileApi(item.id, { userId: this.currentUser.id });
        this.$message.success("已取消收藏");
        this.fetchMyStarredFiles();
      } catch (error) {
        console.error("Failed to unstar file:", error);
        this.$message.error("取消收藏失败");
      }
    },
    getIconClass(item) {
      const ext = item.ext ? item.ext.toLowerCase() : '';
      switch (ext) {
        case 'pdf': return 'el-icon-document color-pdf';
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif': return 'el-icon-picture color-image';
        case 'docx':
        case 'doc': return 'el-icon-document color-word';
        case 'xlsx':
        case 'xls': return 'el-icon-document color-excel';
        case 'pptx':
        case 'ppt': return 'el-icon-document color-ppt';
        case 'xmind': return 'el-icon-s-data color-xmind';
        default: return 'el-icon-document color-default';
      }
    }
  },
};
</script>

<style scoped>
.my-star-list {
  padding: 5px 0;
}

.file-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.file-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 15px;
  border-bottom: 1px solid #f0f2f5;
  cursor: pointer;
  transition: all 0.2s;
}

.file-item:last-child {
  border-bottom: none;
}

.file-item:hover {
  background-color: #f5f7fa;
}

.file-info {
  display: flex;
  align-items: center;
  overflow: hidden;
  flex: 1;
}

.rank-num {
  font-size: 14px;
  font-weight: bold;
  color: #909399;
  width: 24px;
  margin-right: 10px;
  text-align: center;
}

.file-info i {
  font-size: 18px;
  margin-right: 12px;
  flex-shrink: 0;
}

.file-name {
  font-size: 14px;
  color: #606266;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.pin-tag {
  margin-left: 8px;
  transform: scale(0.8);
}

.actions {
  display: flex;
  gap: 10px;
  margin-left: 10px;
  flex-shrink: 0;
}

.actions .el-button {
  padding: 0;
  font-size: 16px;
  color: #909399;
}

.actions .el-button:hover {
  color: #409eff;
}

.actions .delete-btn:hover {
  color: #f56c6c;
}

.empty-text {
  text-align: center;
  color: #909399;
  padding: 20px;
  font-size: 14px;
}

/* 图标颜色 */
.color-pdf { color: #F56C6C; }
.color-image { color: #409EFF; }
.color-word { color: #409EFF; }
.color-excel { color: #67C23A; }
.color-ppt { color: #E6A23C; }
.color-xmind { color: #f39c12; }
.color-default { color: #909399; }
</style>
