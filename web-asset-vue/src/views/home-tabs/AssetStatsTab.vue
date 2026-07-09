<template>
  <div class="tab-content" v-loading="loading">
    <!-- 总览卡片 -->
    <el-row :gutter="20" class="overview-row">
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-card-inner">
            <i class="el-icon-document stats-icon" style="color: #409EFF;"></i>
            <div class="stats-info">
              <div class="stats-value">{{ overview.totalFileCount || 0 }}</div>
              <div class="stats-label">文件总数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-card-inner">
            <i class="el-icon-s-data stats-icon" style="color: #67C23A;"></i>
            <div class="stats-info">
              <div class="stats-value">{{ formatFileSize(overview.totalFileSize) }}</div>
              <div class="stats-label">文件总大小</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-card-inner">
            <i class="el-icon-office-building stats-icon" style="color: #E6A23C;"></i>
            <div class="stats-info">
              <div class="stats-value">{{ overview.totalProductCount || 0 }}</div>
              <div class="stats-label">产品总数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-card-inner">
            <i class="el-icon-view stats-icon" style="color: #F56C6C;"></i>
            <div class="stats-info">
              <div class="stats-value">{{ overview.recent30dAccessCount || 0 }}</div>
              <div class="stats-label">近30天访问量</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 各产品明细表格 -->
    <el-card class="table-card">
      <div slot="header" class="card-header">
        <span><i class="el-icon-menu"></i> 各产品资产明细</span>
      </div>
      <el-table
        :data="productDetails"
        stripe
        style="width: 100%"
        :default-sort="{ prop: 'productFileCount', order: 'descending' }"
        @sort-change="handleSortChange">
        <el-table-column label="产品名称" min-width="180" sortable="custom" prop="productName">
          <template slot-scope="{ row }">
            <span class="product-name-link" @click="goToProduct(row.productId)">{{ row.productName }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="productCode" label="英文简称" width="180" sortable="custom" align="center">
          <template slot-scope="{ row }">
            <span v-if="row.productCode" class="product-code-col">{{ row.productCode }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="productFileCount" label="文件总数" width="100" sortable="custom" align="center">
        </el-table-column>
        <el-table-column label="文件总大小" width="120" sortable="custom" prop="productFileSize" align="center">
          <template slot-scope="{ row }">
            {{ formatFileSize(row.productFileSize) }}
          </template>
        </el-table-column>
        <el-table-column label="最近更新" width="160" sortable="custom" prop="lastUpdateTime" align="center">
          <template slot-scope="{ row }">
            <span v-if="row.lastUpdateTime">{{ row.lastUpdateTime.replace('T', ' ') }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="newFileCount30d" label="近30天新增" width="130" sortable="custom" align="center">
        </el-table-column>
        <el-table-column prop="productAccessCount" label="近30天访问" width="130" sortable="custom" align="center">
        </el-table-column>
        <el-table-column prop="contributorCount" label="维护人数" width="100" sortable="custom" align="center">
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getOverview, getProductDetails } from '@/api/asset-stats'

export default {
  name: "AssetStatsTab",
  data() {
    return {
      loading: false,
      overview: {
        totalFileCount: 0,
        totalFileSize: 0,
        totalProductCount: 0,
        recent30dAccessCount: 0
      },
      productDetails: []
    }
  },
  created() {
    this.fetchData();
  },
  methods: {
    async fetchData() {
      this.loading = true;
      try {
        const [overviewData, detailsData] = await Promise.all([
          getOverview(),
          getProductDetails()
        ]);
        this.overview = overviewData || {};
        this.productDetails = detailsData || [];
      } catch (error) {
        console.error('Failed to load asset stats:', error);
        this.$message.error('加载资产统计数据失败');
      } finally {
        this.loading = false;
      }
    },
    formatFileSize(bytes) {
      if (!bytes || bytes === 0) return '0 B';
      const units = ['B', 'KB', 'MB', 'GB', 'TB'];
      let unitIndex = 0;
      let size = bytes;
      while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
      }
      if (size >= 100) {
        return Math.round(size) + ' ' + units[unitIndex];
      } else if (size >= 10) {
        return size.toFixed(1) + ' ' + units[unitIndex];
      } else {
        return size.toFixed(2) + ' ' + units[unitIndex];
      }
    },
    goToProduct(productId) {
      if (productId) {
        this.$router.push('/product/' + productId);
      }
    },
    handleSortChange({ prop, order }) {
      if (!prop || !order) return;
      const isAsc = order === 'ascending';
      this.productDetails.sort((a, b) => {
        let valA = a[prop];
        let valB = b[prop];
        // null/undefined 排到最后
        if (valA == null && valB == null) return 0;
        if (valA == null) return 1;
        if (valB == null) return -1;
        // 时间字符串比较
        if (prop === 'lastUpdateTime') {
          valA = String(valA);
          valB = String(valB);
        }
        if (typeof valA === 'string') {
          valA = valA.toLowerCase();
          valB = String(valB).toLowerCase();
        }
        if (valA < valB) return isAsc ? -1 : 1;
        if (valA > valB) return isAsc ? 1 : -1;
        return 0;
      });
    }
  }
};
</script>

<style scoped>
.tab-content {
  padding: 10px 0;
}

.overview-row {
  margin-bottom: 20px;
}

.stats-card {
  border-radius: 8px;
}

.stats-card /deep/ .el-card__body {
  padding: 20px;
}

.stats-card-inner {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stats-icon {
  font-size: 40px;
}

.stats-info {
  flex: 1;
}

.stats-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  line-height: 1.2;
}

.stats-label {
  font-size: 13px;
  color: #909399;
  margin-top: 4px;
}

.table-card {
  border-radius: 8px;
}

.table-card /deep/ .el-card__header {
  font-weight: bold;
  color: #303133;
}

.product-name-link {
  color: #409EFF;
  cursor: pointer;
}

.product-name-link:hover {
  text-decoration: underline;
}

.product-code-col {
  color: #909399;
  font-size: 13px;
}

.text-muted {
  color: #C0C4CC;
}
</style>
