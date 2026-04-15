<template>
  <div>
    <div class="zone-header" v-if="showHeader">
      <span>产品专区</span>
      <div class="product-controls">
        <el-radio-group :value="productFilter" @input="handleFilterChange" size="small">
          <el-radio-button label="all">全部产品</el-radio-button>
          <el-radio-button label="favorites" :disabled="favoriteCount === 0">我的收藏 ({{ favoriteCount }})</el-radio-button>
        </el-radio-group>
        
        <el-radio-group :value="viewMode" @input="$emit('update:viewMode', $event)" size="small" style="margin-left: 20px;">
          <el-radio-button label="tile"><i class="el-icon-menu"></i> 平铺</el-radio-button>
          <el-radio-button label="team"><i class="el-icon-s-custom"></i> 按团队</el-radio-button>
          <el-radio-button label="domain"><i class="el-icon-s-data"></i> 按领域</el-radio-button>
        </el-radio-group>
      </div>
    </div>

    <div v-if="viewMode === 'tile'" class="product-grid">
      <div v-for="product in filteredProducts" :key="product.id" class="product-card" @click="$emit('go-to-product', product.id)">
        <div class="product-card-header">
          <span class="product-name">{{ product.productCode || '无简称' }}</span>
          <i 
            :class="product.isFavorited ? 'el-icon-star-on favorite-icon active' : 'el-icon-star-off favorite-icon'"
            @click.stop="$emit('toggle-favorite', product)">
          </i>
        </div>
        <div class="product-card-body">
          <p><strong>产品名称:</strong> {{ product.productName }}</p>
          <p><strong>团队:</strong> {{ product.teamName }}</p>
          <p><strong>领域:</strong> {{ product.domainName }}</p>
          <p><strong>资产数:</strong> {{ product.assetCount }}</p>
          <p><strong>更新时间:</strong> {{ product.updatedAt | formatDate }}</p>
        </div>
      </div>
    </div>

    <div v-else-if="viewMode === 'team'" class="grouped-view">
      <div v-for="(group, teamName) in groupedByTeam" :key="teamName" class="group-section">
        <h3 class="group-title">{{ teamName }}</h3>
        <div class="product-grid">
          <div v-for="product in group" :key="product.id" class="product-card" @click="$emit('go-to-product', product.id)">
            <div class="product-card-header">
              <span class="product-name">{{ product.productName }}</span>
              <i 
                :class="product.isFavorited ? 'el-icon-star-on favorite-icon active' : 'el-icon-star-off favorite-icon'"
                @click.stop="$emit('toggle-favorite', product)">
              </i>
            </div>
            <div class="product-card-body">
              <p><strong>英文简称:</strong> {{ product.productCode || '-' }}</p>
              <p><strong>领域:</strong> {{ product.domainName }}</p>
              <p><strong>资产数:</strong> {{ product.assetCount }}</p>
              <p><strong>更新时间:</strong> {{ product.updatedAt | formatDate }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="viewMode === 'domain'" class="grouped-view">
      <div v-for="(group, domainName) in groupedByDomain" :key="domainName" class="group-section">
        <h3 class="group-title">{{ domainName }}</h3>
        <div class="product-grid">
          <div v-for="product in group" :key="product.id" class="product-card" @click="$emit('go-to-product', product.id)">
            <div class="product-card-header">
              <span class="product-name">{{ product.productName }}</span>
              <i 
                :class="product.isFavorited ? 'el-icon-star-on favorite-icon active' : 'el-icon-star-off favorite-icon'"
                @click.stop="$emit('toggle-favorite', product)">
              </i>
            </div>
            <div class="product-card-body">
              <p><strong>英文简称:</strong> {{ product.productCode || '-' }}</p>
              <p><strong>团队:</strong> {{ product.teamName }}</p>
              <p><strong>资产数:</strong> {{ product.assetCount }}</p>
              <p><strong>更新时间:</strong> {{ product.updatedAt | formatDate }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProductZoneContent',
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
    viewMode: {
      type: String,
      default: 'tile'
    },
    productFilter: {
      type: String,
      default: 'all'
    },
    showHeader: {
      type: Boolean,
      default: true
    },
    isSuperAdmin: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    handleFilterChange(val) {
      this.$emit('update:productFilter', val);
    }
  },
  filters: {
    formatDate(val) {
      if (!val) return '';
      return val.replace('T', ' ');
    }
  }
}
</script>

<style scoped>
.zone-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
  font-size: 18px;
  color: #303133;
  margin-bottom: 16px;
}

.product-controls {
  display: flex;
  align-items: center;
}

/* 产品卡片网格 */
.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.product-card {
  background: #fff;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.3s;
}

.product-card:hover {
  box-shadow: 0 4px 16px 0 rgba(0,0,0,0.1);
  transform: translateY(-2px);
  border-color: #409EFF;
}

.product-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  border-bottom: 1px solid #ebeef5;
  padding-bottom: 12px;
}

.product-name {
  font-size: 16px;
  font-weight: bold;
  color: #303133;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.favorite-icon {
  font-size: 20px;
  color: #c0c4cc;
  cursor: pointer;
}

.favorite-icon.active {
  color: #e6a23c;
}

.product-card-body p {
  margin: 6px 0;
  font-size: 13px;
  color: #606266;
}

.product-card-body strong {
  color: #909399;
  display: inline-block;
  width: 70px;
}

.product-card-footer {
  margin-top: 12px;
  text-align: right;
}

.group-section {
  margin-bottom: 30px;
}

.group-title {
  margin-bottom: 16px;
  padding-bottom: 8px;
  border-bottom: 2px solid #ebeef5;
  color: #409EFF;
  font-size: 18px;
}
</style>
