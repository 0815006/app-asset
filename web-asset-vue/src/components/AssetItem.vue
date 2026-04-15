<template>
  <div class="asset-item" @click="handleClick">
    <div class="item-icon">
      <i :class="iconClass"></i>
    </div>
    <div class="item-content">
      <div class="item-header">
        <span class="item-title">{{ asset.fileName }}</span>
        <el-tag v-if="asset.isNew" type="danger" size="mini" class="new-tag">New</el-tag>
      </div>
      <div class="item-meta">
        <span v-if="asset.ext" class="item-ext">.{{ asset.ext }}</span>
        <span v-if="asset.fileSize" class="item-size">{{ formatFileSize(asset.fileSize) }}</span>
        <span v-if="asset.updatedAt" class="item-date">{{ formatDate(asset.updatedAt) }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import moment from 'moment';

export default {
  name: 'AssetItem',
  props: {
    asset: {
      type: Object,
      required: true
    }
  },
  computed: {
    iconClass() {
      if (this.asset.nodeType === 1) {
        return 'el-icon-folder';
      } else {
        // 根据文件扩展名返回不同的图标
        const ext = this.asset.ext ? this.asset.ext.toLowerCase() : '';
        switch (ext) {
          case 'pdf': return 'el-icon-document';
          case 'jpg':
          case 'jpeg':
          case 'png':
          case 'gif':
          case 'bmp':
          case 'webp': return 'el-icon-picture';
          case 'txt':
          case 'md':
          case 'log':
          case 'sql':
          case 'sh':
          case 'py':
          case 'json':
          case 'xml':
          case 'java':
          case 'js':
          case 'css':
          case 'yml':
          case 'yaml':
          case 'properties':
          case 'ini':
          case 'conf':
          case 'env':
          case 'bat':
          case 'cmd':
          case 'ts':
          case 'vue':
          case 'html':
          case 'c':
          case 'cpp':
          case 'h':
          case 'go':
          case 'php':
          case 'csv': return 'el-icon-document-copy';
          case 'xmind': return 'el-icon-s-data'; // XMind icon
          case 'doc':
          case 'docx': return 'el-icon-document'; // Word
          case 'xls':
          case 'xlsx': return 'el-icon-document'; // Excel
          case 'ppt':
          case 'pptx': return 'el-icon-document'; // PowerPoint
          default: return 'el-icon-document';
        }
      }
    }
  },
  methods: {
    formatFileSize(bytes) {
      if (bytes === 0) return '0 B';
      const k = 1024;
      const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },
    formatDate(dateString) {
      return moment(dateString).format('YYYY-MM-DD HH:mm');
    },
    handleClick() {
      this.$emit('node-click', this.asset);
    }
  }
}
</script>

<style scoped>
.asset-item {
  display: flex;
  align-items: center;
  padding: 10px;
  border-bottom: 1px solid #ebeef5;
  cursor: pointer;
  transition: background-color 0.3s;
}

.asset-item:hover {
  background-color: #f5f7fa;
}

.item-icon {
  font-size: 24px;
  color: #409EFF;
  margin-right: 10px;
}

.item-content {
  flex: 1;
}

.item-header {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
}

.item-title {
  font-size: 16px;
  font-weight: bold;
  color: #303133;
  margin-right: 10px;
}

.new-tag {
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.05);
    opacity: 0.8;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.item-meta {
  font-size: 12px;
  color: #909399;
}

.item-meta span {
  margin-right: 10px;
}
</style>