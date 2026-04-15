<template>
  <div class="tab-content search-tab">
    <div class="hero-section">
      <div class="hero-content">
        <h1 class="hero-title">探索业务资产</h1>
        <div class="search-box-large">
          <el-input
            placeholder="在全库中搜索文档、产品、规范..."
            v-model="globalSearchQuery"
            class="large-search-input"
            @keyup.enter.native="performSearch(globalSearchQuery, 'global')"
            clearable>
            <el-button slot="append" icon="el-icon-search" type="primary" @click="performSearch(globalSearchQuery, 'global')">搜索</el-button>
          </el-input>
        </div>
        <div class="hot-search-terms">
          <h3><i class="el-icon-hot-water"></i> 热门搜索词</h3>
          <hot-search-list @search="performSearch($event, 'global')"></hot-search-list>
        </div>  
      </div>
    </div>

    <div class="ranking-section">
      <el-row :gutter="20">
        <el-col :span="8">
          <el-card class="ranking-card">
            <div slot="header" class="card-header">
              <span><i class="el-icon-data-line"></i> 访问排行榜</span>
            </div>
            <global-use-top-list @node-click="handleSearchResultClick"></global-use-top-list>
          </el-card>
        </el-col>
        <el-col :span="8">
          <el-card class="ranking-card">
            <div slot="header" class="card-header">
              <span><i class="el-icon-star-on"></i> 资产人气榜</span>
            </div>
            <global-star-top-list @node-click="handleSearchResultClick"></global-star-top-list>
          </el-card>
        </el-col>
        <el-col :span="8">
          <el-card class="ranking-card">
            <div slot="header" class="card-header">
              <span><i class="el-icon-refresh"></i> 最新更新</span>
            </div>
            <latest-updates-list @node-click="handleSearchResultClick"></latest-updates-list>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script>
import HotSearchList from '../../components/HotSearchList.vue'
import GlobalUseTopList from '../../components/GlobalUseTopList.vue'
import GlobalStarTopList from '../../components/GlobalStarTopList.vue'
import LatestUpdatesList from '../../components/LatestUpdatesList.vue'

export default {
  name: 'SearchFirstTab',
  components: {
    HotSearchList,
    GlobalUseTopList,
    GlobalStarTopList,
    LatestUpdatesList
  },
  data() {
    return {
      globalSearchQuery: ''
    }
  },
  methods: {
    performSearch(query, scope) {
      this.$emit('search', query, scope);
    },
    handleSearchResultClick(item) {
      this.$emit('node-click', item);
    }
  }
}
</script>

<style scoped>
.tab-content {
  padding: 10px 0;
}

/* 智能探索样式 */
.hero-section {
  padding: 40px 0;
  text-align: center;
  background-color: #fff;
  border-radius: 8px;
  margin-bottom: 30px;
}

.hero-title {
  font-size: 28px;
  color: #409EFF;
  margin-bottom: 30px;
  font-weight: bold;
  letter-spacing: 2px;
}

.search-box-large {
  max-width: 700px;
  margin: 0 auto 30px;
}

.large-search-input /deep/ .el-input__inner {
  height: 50px;
  line-height: 50px;
  font-size: 16px;
}

.large-search-input /deep/ .el-input-group__append {
  background-color: #409EFF;
  color: white;
  border-color: #409EFF;
  padding: 0 30px;
  font-size: 16px;
}

.hot-search-terms h3 {
  font-size: 14px;
  color: #909399;
  margin-bottom: 12px;
}

.ranking-section {
  margin-top: 20px;
}

.ranking-card {
  height: 100%;
}

.card-header {
  font-size: 15px;
  font-weight: bold;
  color: #303133;
  display: flex;
  align-items: center;
}

.card-header i {
  margin-right: 8px;
  color: #409EFF;
}
</style>