<template>
  <el-dialog
    title="索引库健康检查"
    :visible.sync="localVisible"
    width="1000px"
    top="5vh"
    custom-class="health-check-dialog">
    
    <div class="dialog-content" v-loading="loading">
      <div class="summary-bar">
        <div class="stat-item">
          <span class="label">本地数据库文件数：</span>
          <span class="value">{{ dbCount }}</span>
        </div>
        <div class="stat-item">
          <span class="label">Solr 服务器文档数：</span>
          <span class="value">{{ solrCount }}</span>
        </div>
        <div class="actions">
          <el-button type="primary" size="small" icon="el-icon-search" @click="startCheck" :loading="checking">开始检查</el-button>
          
          <el-tooltip content="所有缺失的文件将在 Solr 服务器上全部重建索引，重建后才能被搜索到" placement="top">
            <el-button type="warning" size="small" icon="el-icon-refresh" @click="handleRepairAll" :disabled="!checkDone || missingIds.length === 0">全部修复</el-button>
          </el-tooltip>
          
          <el-tooltip content="清除 Solr 服务器上所有多余的文件" placement="top">
            <el-button type="danger" size="small" icon="el-icon-delete" @click="handleCleanAll" :disabled="!checkDone || extraSolrIds.length === 0">全部清理</el-button>
          </el-tooltip>
        </div>
      </div>

      <el-table :data="comparisonList" border height="500px" style="width: 100%; margin-top: 20px;">
        <el-table-column label="本地数据库 (AssetFile)" min-width="200">
          <template slot-scope="scope">
            <div v-if="scope.row.dbFile" class="file-info">
              <div class="name">{{ scope.row.dbFile.fileName }}</div>
              <div class="id">ID: {{ scope.row.dbFile.id }}</div>
            </div>
            <div v-else class="empty-cell">-</div>
          </template>
        </el-table-column>

        <el-table-column label="Solr 索引库 (Document)" min-width="200">
          <template slot-scope="scope">
            <div v-if="scope.row.solrDoc" class="file-info" :class="{ 'matched': scope.row.status === 'matched' }">
              <div class="name">文件名: {{ scope.row.solrDoc.name }}</div>
              <div class="id">索引 ID: {{ scope.row.solrDoc.id }}</div>
            </div>
            <div v-else class="empty-cell">-</div>
          </template>
        </el-table-column>

        <el-table-column label="状态" width="120" align="center">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 'matched'" type="success">已匹配</el-tag>
            <el-tag v-else-if="scope.row.status === 'missing'" type="danger">索引缺失</el-tag>
            <el-tag v-else-if="scope.row.status === 'extra'" type="warning">索引多余</el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="150" align="center">
          <template slot-scope="scope">
            <el-button 
              v-if="scope.row.status === 'missing'" 
              type="text" 
              size="mini" 
              icon="el-icon-refresh"
              @click="reindex(scope.row.dbFile.id)">重建索引</el-button>
            <el-button 
              v-if="scope.row.status === 'extra'" 
              type="text" 
              size="mini" 
              icon="el-icon-delete"
              class="danger-text"
              @click="cleanIndex(scope.row.solrDoc.id)">清理索引</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div slot="footer" class="dialog-footer" style="display: flex; justify-content: flex-start; align-items: center; width: 100%;">
      <div class="footer-left" style="flex: 1; display: flex; align-items: center;">
        <el-tooltip content="重新遍历所有文件并建立索引（支持内容检索），耗时较长" placement="top">
          <el-button type="primary" size="small" icon="el-icon-s-operation" @click="handleRebuildAll" :disabled="isRebuilding">全部重建</el-button>
        </el-tooltip>
        
        <div v-if="isRebuilding" style="flex: 1; margin-left: 10px; display: flex; align-items: center;">
          <span style="font-size: 13px; color: #606266; margin-right: 10px; white-space: nowrap;">
            重建进度: {{ rebuildCurrent }} / {{ rebuildTotal }}
          </span>
          <el-progress 
            :percentage="rebuildPercentage" 
            :status="rebuildPercentage === 100 ? 'success' : null"
            style="flex: 1;">
          </el-progress>
        </div>
      </div>
    </div>
  </el-dialog>
</template>

<script>
import { getSearchHealthCheck, reindexAsset, deleteSearchIndex, startRebuildAll, getRebuildProgress } from '@/api/search'

export default {
  name: 'IndexHealthCheckDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      loading: false,
      checking: false,
      checkDone: false,
      dbCount: 0,
      solrCount: 0,
      comparisonList: [],
      missingIds: [],
      extraSolrIds: [],
      isRebuilding: false,
      rebuildTotal: 0,
      rebuildCurrent: 0,
      rebuildTimer: null
    }
  },
  computed: {
    localVisible: {
      get() { return this.visible },
      set(val) { this.$emit('update:visible', val) }
    },
    rebuildPercentage() {
      if (this.rebuildTotal === 0) return 0;
      return Math.floor((this.rebuildCurrent / this.rebuildTotal) * 100);
    }
  },
  watch: {
    visible(val) {
      if (val) {
        this.checkRebuildStatus();
      } else {
        this.stopPolling();
      }
    }
  },
  beforeDestroy() {
    this.stopPolling();
  },
  methods: {
    async checkRebuildStatus() {
      try {
        const res = await getRebuildProgress();
        if (res) {
          const wasRebuilding = this.isRebuilding;
          this.isRebuilding = res.isRebuilding;
          this.rebuildTotal = res.total;
          this.rebuildCurrent = res.current;
          
          if (this.isRebuilding) {
            this.startPolling();
          } else {
            this.stopPolling();
            if (wasRebuilding && this.rebuildTotal > 0) {
              this.$message.success('全库重建完成');
              this.startCheck();
            }
          }
        }
      } catch (e) {
        console.error('获取重建进度失败', e);
      }
    },
    startPolling() {
      if (!this.rebuildTimer) {
        this.rebuildTimer = setInterval(() => {
          this.checkRebuildStatus();
        }, 2000);
      }
    },
    stopPolling() {
      if (this.rebuildTimer) {
        clearInterval(this.rebuildTimer);
        this.rebuildTimer = null;
      }
    },
    async handleRebuildAll() {
      try {
        await this.$confirm('此操作将重新遍历所有文件并建立索引，耗时较长，是否继续？', '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        });
        
        await startRebuildAll();
        this.$message.success('已开始全库重建任务');
        this.isRebuilding = true;
        this.rebuildTotal = 0;
        this.rebuildCurrent = 0;
        this.startPolling();
      } catch (e) {
        if (e !== 'cancel') {
          console.error(e);
        }
      }
    },
    async startCheck() {
      this.checking = true;
      this.loading = true;
      try {
        const res = await getSearchHealthCheck();
        // request.js 已经返回了 res.data
        const { dbFiles, solrDocs, dbCount, solrCount } = res;
        
        this.dbCount = dbCount || 0;
        this.solrCount = solrCount || 0;
        
        const list = [];
        const solrMap = new Map();
        if (solrDocs) {
          solrDocs.forEach(doc => solrMap.set(doc.id.toString(), doc));
        }
        
        const processedSolrIds = new Set();
        this.missingIds = [];
        
        // 1. 以数据库为基准
        if (dbFiles) {
          dbFiles.forEach(file => {
            const solrDoc = solrMap.get(file.id.toString());
            if (solrDoc) {
              list.push({ dbFile: file, solrDoc, status: 'matched' });
              processedSolrIds.add(file.id.toString());
            } else {
              list.push({ dbFile: file, solrDoc: null, status: 'missing' });
              this.missingIds.push(file.id);
            }
          });
        }
        
        // 2. 找出 Solr 中多余的
        this.extraSolrIds = [];
        if (solrDocs) {
          solrDocs.forEach(doc => {
            if (!processedSolrIds.has(doc.id.toString())) {
              list.push({ dbFile: null, solrDoc: doc, status: 'extra' });
              this.extraSolrIds.push(doc.id.toString());
            }
          });
        }
        
        this.comparisonList = list;
        this.checkDone = true;
      } catch (e) {
        console.error(e);
      } finally {
        this.checking = false;
        this.loading = false;
      }
    },
    async reindex(id) {
      try {
        await reindexAsset(id);
        this.$message.success('重建索引成功');
        this.startCheck();
      } catch (e) {}
    },
    async cleanIndex(solrId) {
      try {
        await deleteSearchIndex(solrId);
        this.$message.success('清理索引成功');
        this.startCheck();
      } catch (e) {}
    },
    async handleRepairAll() {
      this.loading = true;
      try {
        for (const id of this.missingIds) {
          await reindexAsset(id);
        }
        this.$message.success('全部修复完成');
        this.startCheck();
      } catch (e) {
        console.error(e);
      } finally {
        this.loading = false;
      }
    },
    async handleCleanAll() {
      this.loading = true;
      try {
        for (const solrId of this.extraSolrIds) {
          await deleteSearchIndex(solrId);
        }
        this.$message.success('全部清理完成');
        this.startCheck();
      } catch (e) {
        console.error(e);
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>

<style scoped>
.summary-bar {
  display: flex;
  align-items: center;
  background-color: #f8f9fa;
  padding: 15px 20px;
  border-radius: 4px;
}

.stat-item {
  margin-right: 40px;
}

.stat-item .label {
  color: #909399;
  font-size: 14px;
}

.stat-item .value {
  color: #303133;
  font-size: 18px;
  font-weight: bold;
}

.actions {
  margin-left: auto;
}

.file-info .name {
  font-weight: bold;
  color: #303133;
}

.file-info .id {
  font-size: 12px;
  color: #909399;
}

.file-info.matched .name {
  color: #67C23A;
}

.empty-cell {
  color: #C0C4CC;
  font-style: italic;
}

.danger-text {
  color: #F56C6C;
}
</style>
