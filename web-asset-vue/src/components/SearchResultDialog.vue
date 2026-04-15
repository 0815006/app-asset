<template>
  <el-dialog
    :title="`全库搜索结果: &quot;${query}&quot;`"
    :visible.sync="localVisible"
    width="900px"
    custom-class="search-result-dialog"
    top="5vh"
    append-to-body>
    
    <div class="search-results-container" v-loading="loading">
      <div class="search-summary" v-if="total > 0">
        找到约 {{ total }} 条结果
      </div>

      <div v-if="results.length === 0 && !loading" class="no-results">
        <el-empty description="未找到相关内容，请尝试更换关键词"></el-empty>
      </div>
      
      <div v-else class="result-list">
        <div v-for="(item, index) in results" :key="index" class="result-item" @click="handleResultClick(item)">
          <div class="result-header">
            <i :class="getFileIcon(item)" class="file-icon"></i>
            <span class="result-title" v-html="highlightTitle(item.label, query)"></span>
            <el-tag size="mini" type="info" class="result-type-tag" v-if="item.isProduct">产品</el-tag>
            <el-tag size="mini" class="result-type-tag" v-else>文档</el-tag>
          </div>
          
          <div class="result-path">
            <span class="path-label">所属区域：</span>
            <span class="zone-name">{{ item.zoneName }}</span>
          </div>
          
          <div class="result-context" v-html="formatContext(item.context, query)"></div>
        </div>
      </div>

      <div class="pagination-container" v-if="total > pageSize">
        <el-pagination
          background
          layout="total, prev, pager, next"
          :current-page="currentPage"
          :page-size="pageSize"
          :total="total"
          @current-change="handlePageChange">
        </el-pagination>
      </div>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: 'SearchResultDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    query: {
      type: String,
      default: ''
    },
    results: {
      type: Array,
      default: () => []
    },
    total: {
      type: Number,
      default: 0
    },
    loading: {
      type: Boolean,
      default: false
    },
    currentPage: {
      type: Number,
      default: 1
    },
    pageSize: {
      type: Number,
      default: 10
    }
  },
  computed: {
    localVisible: {
      get() { return this.visible; },
      set(val) { this.$emit('update:visible', val); }
    }
  },
  methods: {
    getFileIcon(item) {
      if (item.isProduct) return 'el-icon-box';
      // Ensure item.ext is a string before calling toLowerCase()
      const ext = String(item.ext || '').toLowerCase();
      if (['pdf'].includes(ext)) return 'el-icon-document';
      if (['doc', 'docx'].includes(ext)) return 'el-icon-document-word';
      if (['xls', 'xlsx', 'csv'].includes(ext)) return 'el-icon-document-excel';
      if (['ppt', 'pptx'].includes(ext)) return 'el-icon-data-board';
      if (['jpg', 'jpeg', 'png', 'gif'].includes(ext)) return 'el-icon-picture-outline';
      if (['txt', 'md'].includes(ext)) return 'el-icon-tickets';
      return 'el-icon-document';
    },
    highlightTitle(text, query) {
      const safeText = String(text || '');
      if (!query || !safeText) return safeText;
      const reg = new RegExp(`(${this.escapeRegExp(query)})`, 'gi');
      return safeText.replace(reg, '<em class="highlight-keyword">$1</em>');
    },
    formatContext(text, query) {
      const safeText = String(text || '');
      if (!safeText) return '暂无内容预览';
      
      // 如果后端已经返回了带有 <em> 标签的高亮内容（Solr 默认行为），则直接信任并稍微处理一下样式
      if (safeText.includes('<em') || safeText.includes('</em>')) {
        // 将后端的 <em style='color:red'> 替换为统一的 class，方便前端控制样式
        return safeText.replace(/<em[^>]*>/gi, '<em class="highlight-keyword">');
      }
      
      // 如果是前端本地搜索（如产品搜索），则手动高亮
      if (query) {
        const reg = new RegExp(`(${this.escapeRegExp(query)})`, 'gi');
        return safeText.replace(reg, '<em class="highlight-keyword">$1</em>');
      }
      
      return safeText;
    },
    escapeRegExp(string) {
      return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    },
    handleResultClick(item) {
      this.$emit('item-click', item);
      this.localVisible = false;
    },
    handlePageChange(page) {
      this.$emit('page-change', page);
    }
  }
}
</script>

<style scoped>
.search-result-dialog /deep/ .el-dialog__body {
  padding-top: 10px;
  padding-bottom: 20px;
}

.search-results-container {
  max-height: 65vh;
  overflow-y: auto;
  padding-right: 15px;
}

/* 自定义滚动条 */
.search-results-container::-webkit-scrollbar {
  width: 6px;
}
.search-results-container::-webkit-scrollbar-thumb {
  background-color: #c0c4cc;
  border-radius: 3px;
}

.search-summary {
  font-size: 13px;
  color: #909399;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #ebeef5;
}

.result-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.result-item {
  padding: 15px;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.result-item:hover {
  background-color: #f5f7fa;
}

.result-header {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
}

.file-icon {
  font-size: 18px;
  color: #909399;
  margin-right: 8px;
}

.result-title {
  font-size: 18px;
  color: #1a0dab; /* 类似 Google 的标题蓝 */
  font-weight: 500;
  line-height: 1.4;
  text-decoration: none;
}

.result-item:hover .result-title {
  text-decoration: underline;
}

.result-type-tag {
  margin-left: 10px;
  transform: scale(0.9);
}

.result-path {
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  font-size: 13px;
}

.path-label {
  color: #5f6368;
  margin-right: 5px;
  white-space: nowrap;
}

.zone-name {
  color: #006621; /* 类似 Google 的路径绿 */
  font-weight: normal;
}

.result-path /deep/ .el-breadcrumb__inner {
  color: #006621; /* 类似 Google 的路径绿 */
  font-weight: normal;
}

.result-path /deep/ .el-breadcrumb__separator {
  margin: 0 3px;
  color: #5f6368;
}

.result-context {
  font-size: 14px;
  color: #4d5156; /* 类似 Google 的摘要灰 */
  line-height: 1.6;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3; /* 最多显示3行摘要 */
  overflow: hidden;
  word-break: break-all;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: center;
  padding-top: 15px;
  border-top: 1px solid #ebeef5;
}
</style>

<style>
/* 全局样式，用于 v-html 渲染的高亮标签 */
.highlight-keyword {
  color: #ea4335; /* 红色高亮 */
  font-style: normal;
  font-weight: bold;
  background-color: transparent;
}
</style>
