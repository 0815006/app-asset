<template>
  <div class="product-curated-asset-list">
    <div v-if="curatedList.length === 0" class="empty-text">暂无核心资产</div>
    <el-row :gutter="15" class="curated-grid">
      <el-col :span="6" v-for="item in curatedList" :key="item.id" class="grid-item-col">
        <div class="curated-item-card" @click="handleItemClick(item)">
          <div class="item-icon">
            <i :class="getIconClass(item)"></i>
          </div>
          <div class="item-name" :title="item.fileName">{{ item.fileName }}</div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { getProductCuratedAssets } from '@/api/asset-node'; // Assuming this API will be added
import { getBatchDetails } from '@/api/asset-node';

export default {
  name: 'ProductCuratedAssetList',
  props: {
    productId: {
      type: [String, Number],
      required: true
    }
  },
  data() {
    return {
      curatedList: []
    };
  },
  watch: {
    productId: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.fetchProductCuratedAssets();
        }
      }
    }
  },
  methods: {
    async fetchProductCuratedAssets() {
      try {
        const res = await getProductCuratedAssets(this.productId);
        const fileIds = (res || []).map(item => item.fileId);
        if (fileIds.length > 0) {
          const currentUser = JSON.parse(localStorage.getItem('userInfo') || '{}');
          const details = await getBatchDetails({ ids: fileIds, userId: currentUser.id });
          const detailMap = (details || []).reduce((acc, curr) => {
            acc[curr.id] = curr;
            return acc;
          }, {});

          this.curatedList = (res || []).map(item => ({
            ...item,
            ...(detailMap[item.fileId] || { fileName: `未知文件(${item.fileId})` })
          })).filter(item => detailMap[item.fileId]); // 展示全部核心资产，不再控制条数
        } else {
          this.curatedList = [];
        }
      } catch (error) {
        console.error("Failed to fetch product curated assets:", error);
        this.$message.error("获取产品核心资产失败");
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

.product-curated-asset-list {
  padding: 5px 0;
}

.curated-grid {
  display: flex;
  flex-wrap: wrap;
}

.grid-item-col {
  margin-bottom: 10px; /* 减小行间距 */
}

.curated-item-card {
  background-color: #f8f9fa;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 5px; /* 极简内边距 */
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  height: 70px; /* 进一步压缩高度 */
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.curated-item-card:hover {
  background-color: #fff;
  border-color: #409EFF;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transform: translateY(-2px);
}

.item-icon {
  font-size: 20px; /* 进一步缩小图标 */
  margin-bottom: 2px;
}

.item-name {
  font-size: 11px;
  color: #606266;
  line-height: 1.2;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  overflow: hidden;
  word-break: break-all;
  padding: 0 2px;
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