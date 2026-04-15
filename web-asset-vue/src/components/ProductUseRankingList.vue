<template>
  <div class="product-use-ranking-list global-use-top-list">
    <div v-if="rankingList.length === 0" class="empty-text">暂无使用排行数据</div>
    <ul class="file-list">
      <li v-for="(item, index) in rankingList" :key="item.id" class="file-item" @click="handleItemClick(item)">
        <div class="file-info">
          <span class="rank-num" :class="'rank-' + (index + 1)">{{ index + 1 }}</span>
          <i :class="getIconClass(item)"></i>
          <span class="file-name" :title="item.fileName">{{ item.fileName }}</span>
        </div>
        <span class="use-count">{{ item.useCount }} 次访问</span>
      </li>
    </ul>
  </div>
</template>

<script>
import { getProductUseRanking } from '@/api/asset-node'; // Assuming this API will be added
import { getBatchDetails } from '@/api/asset-node';

export default {
  name: 'ProductUseRankingList',
  props: {
    productId: {
      type: [String, Number],
      required: true
    }
  },
  data() {
    return {
      rankingList: []
    };
  },
  watch: {
    productId: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.fetchProductUseRanking();
        }
      }
    }
  },
  methods: {
    async fetchProductUseRanking() {
      try {
        const res = await getProductUseRanking(this.productId);
        const fileIds = (res || []).map(item => item.fileId);
        if (fileIds.length > 0) {
          const currentUser = JSON.parse(localStorage.getItem('userInfo') || '{}');
          const details = await getBatchDetails({ ids: fileIds, userId: currentUser.id });
          const detailMap = (details || []).reduce((acc, curr) => {
            acc[curr.id] = curr;
            return acc;
          }, {});

          this.rankingList = (res || []).map(item => ({
            ...item,
            ...(detailMap[item.fileId] || { fileName: `未知文件(${item.fileId})` })
          })).filter(item => detailMap[item.fileId]).slice(0, 10); // 只显示存在的，且最多10条
        } else {
          this.rankingList = [];
        }
      } catch (error) {
        console.error("Failed to fetch product use ranking:", error);
        this.$message.error("获取产品使用排行失败");
      }
    },
    handleItemClick(item) {
      this.$emit("node-click", item);
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
  }
};
</script>

<style scoped>
@import '../assets/global.css'; /* 引入全局样式，确保图标颜色等一致 */

.product-use-ranking-list {
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

.rank-1 { color: #f56c6c; }
.rank-2 { color: #e6a23c; }
.rank-3 { color: #409eff; }

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

.use-count {
  font-size: 12px;
  color: #909399;
  margin-left: 10px;
  flex-shrink: 0;
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