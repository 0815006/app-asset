<template>
  <div class="tab-content">
    <div class="zone-header-actions">
      <el-radio-group v-model="zoneViewMode" size="medium">
        <el-radio-button label="product">产品专区</el-radio-button>
        <el-radio-button label="tech">测试技术与工艺专区</el-radio-button>
        <el-radio-button label="mgmt">测试管理专区</el-radio-button>
      </el-radio-group>
      
      <div class="admin-actions" v-if="isSuperAdmin">
        <el-button
          type="warning"
          size="small"
          icon="el-icon-setting"
          plain
          @click="showProductMgmt">维护产品信息</el-button>
        <el-button
          type="warning"
          size="small"
          icon="el-icon-monitor"
          plain
          @click="showHealthCheck">存储健康检查</el-button>
        <el-button
          type="warning"
          size="small"
          icon="el-icon-search"
          plain
          @click="showIndexHealthCheck">索引健康检查</el-button>
        <el-button
          type="danger"
          size="small"
          icon="el-icon-delete"
          plain
          @click="showRecycleBin">回收站</el-button>
      </div>
    </div>

    <div class="zone-content-area">
      <div v-if="zoneViewMode === 'tech'" class="zone-wrapper tech-zone">
        <tech-zone-content
          :search-query="techSearchQuery"
          :tree-data="techTreeData"
          :root-id="techRootId"
          :default-props="defaultProps"
          @search="performSearch($event, 'tech')"
          @node-click="handleNodeClick($event, 'tech')"
          @update:searchQuery="techSearchQuery = $event"
          @refresh="fetchData"
          ref="techTreeTab"
        />
      </div>
      <div v-else-if="zoneViewMode === 'product'" class="zone-wrapper product-zone">
        <product-zone-content
          :is-super-admin="isSuperAdmin"
          :products="products"
          :filtered-products="filteredProducts"
          :grouped-by-team="groupedByTeam"
          :grouped-by-domain="groupedByDomain"
          :favorite-count="favoriteCount"
          :view-mode.sync="viewMode"
          :product-filter="productFilter"
          @update:productFilter="$emit('update:productFilter', $event)"
          @toggle-favorite="toggleFavorite"
          @go-to-product="goToProduct"
          @show-product-mgmt="showProductMgmt"
        />
      </div>
      <div v-else-if="zoneViewMode === 'mgmt'" class="zone-wrapper mgmt-zone">
        <mgmt-zone-content
          :search-query="mgmtSearchQuery"
          :tree-data="mgmtTreeData"
          :root-id="mgmtRootId"
          :default-props="defaultProps"
          @search="performSearch($event, 'mgmt')"
          @node-click="handleNodeClick($event, 'mgmt')"
          @update:searchQuery="mgmtSearchQuery = $event"
          @refresh="fetchData"
          ref="mgmtTreeTab"
        />
      </div>
    </div>
  </div>
</template>

<script>
import TechZoneContent from '../../components/TechZoneContent.vue'
import ProductZoneContent from '../../components/ProductZoneContent.vue'
import MgmtZoneContent from '../../components/MgmtZoneContent.vue'
import { toggleFavorite as toggleFavoriteApi } from '@/api/product'
import { getAssetTree } from '@/api/asset-node'

export default {
  name: 'BusinessLandscapeTab',
  components: {
    TechZoneContent,
    ProductZoneContent,
    MgmtZoneContent
  },
  props: {
    products: {
      type: Array,
      default: () => []
    },
    filteredProducts: {
      type: Array,
      default: () => []
    },
    groupedByTeam: {
      type: Object,
      default: () => ({})
    },
    groupedByDomain: {
      type: Object,
      default: () => ({})
    },
    favoriteCount: {
      type: Number,
      default: 0
    },
    techTreeData: {
      type: Array,
      default: () => []
    },
    mgmtTreeData: {
      type: Array,
      default: () => []
    },
    techRootId: {
      type: [Number, String],
      default: null
    },
    mgmtRootId: {
      type: [Number, String],
      default: null
    },
    defaultProps: {
      type: Object,
      default: () => ({})
    },
    productFilter: {
      type: String,
      default: 'all'
    }
  },
  data() {
    return {
      zoneViewMode: 'product',
      techSearchQuery: '',
      mgmtSearchQuery: '',
      viewMode: 'tile',
      currentUser: JSON.parse(localStorage.getItem('userInfo') || '{}')
    }
  },
  computed: {
    isSuperAdmin() {
      return this.currentUser && this.currentUser.roleType === 1;
    }
  },
  methods: {
    showProductMgmt() {
      this.$emit('show-product-mgmt');
    },
    showHealthCheck() {
      this.$emit('show-health-check');
    },
    showIndexHealthCheck() {
      this.$emit('show-index-health-check');
    },
    showRecycleBin() {
      this.$emit('show-recycle-bin');
    },
    performSearch(query, scope) {
      this.$emit('search', query, scope);
    },
    handleNodeClick(data, zoneType) {
      this.$emit('node-click', data, zoneType);
    },
    async toggleFavorite(product) {
      const newStatus = !product.isFavorited;
      const action = newStatus ? 1 : 0;
      try {
        await toggleFavoriteApi(product.id, action);
        // Emit an event to Home.vue to re-fetch products or update the specific product
        this.$emit('toggle-favorite-success', product.id, newStatus);
        this.$message.success(newStatus ? '收藏成功' : '已取消收藏');
      } catch (error) {
        console.error('收藏操作失败', error);
        this.$message.error('收藏操作失败');
      }
    },
    goToProduct(id) {
      this.$emit('go-to-product', id);
    },
    fetchData() {
      this.$emit('refresh-data');
    }
  }
}
</script>

<style scoped>
.tab-content {
  padding: 10px 0;
}

.zone-header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #ebeef5;
}

.admin-actions .el-button {
  margin-left: 10px;
}
</style>