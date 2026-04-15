<template>
  <el-dialog
    title="回收站管理"
    :visible.sync="localVisible"
    width="900px"
    custom-class="recycle-bin-dialog"
    append-to-body
    @open="fetchData">
    
    <div class="recycle-bin-container" v-loading="loading">
      <!-- 批量操作进度条 -->
      <div v-if="isBatching" class="batch-progress-wrapper">
        <div class="progress-info">正在处理批量任务... {{ batchProgress.current }} / {{ batchProgress.total }}</div>
        <el-progress :percentage="progressPercentage" :status="progressStatus" :stroke-width="18" text-inside></el-progress>
      </div>

      <el-table :data="deletedFiles" stripe style="width: 100%" max-height="500">
        <el-table-column prop="fileName" label="文件名" min-width="200">
          <template slot-scope="scope">
            <i :class="scope.row.nodeType === 1 ? 'el-icon-folder' : 'el-icon-document'" style="margin-right: 8px; color: #909399;"></i>
            <span>{{ scope.row.fileName }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="originalPath" label="原存储路径" min-width="250">
          <template slot-scope="scope">
            <span class="path-text" :title="scope.row.originalPath">{{ scope.row.originalPath }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="updatedAt" label="删除时间" width="180">
          <template slot-scope="scope">
            {{ formatTime(scope.row.updatedAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template slot-scope="scope">
            <el-button
              size="mini"
              type="success"
              plain
              icon="el-icon-refresh-left"
              @click="handleRestore(scope.row)">恢复</el-button>
            <el-button
              size="mini"
              type="danger"
              plain
              icon="el-icon-delete"
              @click="handlePermanentDelete(scope.row)">清理</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <div v-if="deletedFiles.length === 0 && !loading" class="empty-state">
        <i class="el-icon-delete-solid"></i>
        <p>回收站空空如也</p>
      </div>
    </div>
    
    <div slot="footer" class="dialog-footer">
      <div class="footer-left" v-if="deletedFiles.length > 0 && !isBatching">
        <el-button type="success" size="small" icon="el-icon-refresh-left" @click="handleRestoreAll">全部恢复</el-button>
        <el-button type="danger" size="small" icon="el-icon-delete" @click="handlePermanentDeleteAll">全部清理</el-button>
      </div>
      <el-button @click="localVisible = false" :disabled="isBatching">关 闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getRecycleBin, restoreAsset, permanentDeleteAsset, restoreAllAssets, permanentDeleteAllAssets, getBatchProgress } from '@/api/asset-node'

export default {
  name: 'RecycleBinDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      deletedFiles: [],
      loading: false,
      isBatching: false,
      batchTaskId: null,
      batchProgress: {
        total: 0,
        current: 0,
        status: 'running'
      },
      timer: null
    }
  },
  computed: {
    localVisible: {
      get() { return this.visible },
      set(val) { this.$emit('update:visible', val) }
    },
    progressPercentage() {
      if (!this.batchProgress.total) return 0
      return Math.floor((this.batchProgress.current / this.batchProgress.total) * 100)
    },
    progressStatus() {
      if (this.batchProgress.status === 'finished') return 'success'
      if (this.batchProgress.status === 'error') return 'exception'
      return null
    }
  },
  methods: {
    async fetchData() {
      this.loading = true
      try {
        const res = await getRecycleBin()
        this.deletedFiles = res || []
      } catch (error) {
        console.error('Failed to fetch recycle bin:', error)
      } finally {
        this.loading = false
      }
    },
    async handleRestore(row) {
      try {
        await restoreAsset(row.id)
        this.$message.success(`文件 "${row.fileName}" 已成功恢复`)
        this.fetchData()
        this.$emit('refresh-data') // 通知首页刷新目录树
      } catch (error) {
        // 错误已由 axios 拦截器处理并弹出提示
        console.error('Restore failed:', error)
      }
    },
    async handlePermanentDelete(row) {
      try {
        await this.$confirm(`确定要清理文件 "${row.fileName}" 吗？此操作将彻底从存储中移除且不可恢复！`, '清理确认', {
          confirmButtonText: '确定清理',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        await permanentDeleteAsset(row.id)
        this.$message.success('文件已清理')
        this.fetchData()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Permanent delete failed:', error)
        }
      }
    },
    async handleRestoreAll() {
      try {
        await this.$confirm('确定要恢复回收站中的所有文件吗？', '批量恢复确认', {
          confirmButtonText: '确定恢复全部',
          cancelButtonText: '取消',
          type: 'info'
        })
        
        const taskId = await restoreAllAssets()
        this.batchTaskId = taskId
        this.isBatching = true
        this.startPolling()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Batch restore failed:', error)
        }
      }
    },
    async handlePermanentDeleteAll() {
      try {
        await this.$confirm('确定要清理回收站中的所有文件吗？此操作不可逆！', '批量清理确认', {
          confirmButtonText: '确定清理全部',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        const taskId = await permanentDeleteAllAssets()
        this.batchTaskId = taskId
        this.isBatching = true
        this.startPolling()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Batch permanent delete failed:', error)
        }
      }
    },
    startPolling() {
      this.timer = setInterval(async () => {
        try {
          const res = await getBatchProgress(this.batchTaskId)
          this.batchProgress = res
          if (res.status === 'finished' || res.status === 'error') {
            this.stopPolling()
            if (res.status === 'finished') {
              this.$message.success('批量任务处理完成')
              this.$emit('refresh-data')
            } else {
              this.$message.error('批量任务处理失败: ' + res.message)
            }
            setTimeout(() => {
              this.isBatching = false
              this.fetchData()
            }, 2000)
          }
        } catch (error) {
          console.error('Polling failed:', error)
          this.stopPolling()
          this.isBatching = false
        }
      }, 800)
    },
    stopPolling() {
      if (this.timer) {
        clearInterval(this.timer)
        this.timer = null
      }
    },
    formatTime(timeStr) {
      if (!timeStr) return ''
      return timeStr.replace('T', ' ').split('.')[0]
    }
  }
}
</script>

<style scoped>
.recycle-bin-container {
  min-height: 200px;
}

.batch-progress-wrapper {
  margin-bottom: 20px;
  padding: 15px;
  background: rgba(64, 158, 255, 0.05);
  border-radius: 4px;
  border: 1px dashed #409EFF;
}

.progress-info {
  margin-bottom: 10px;
  font-size: 14px;
  color: #409EFF;
  font-weight: bold;
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.path-text {
  color: #67c23a;
  font-family: monospace;
  font-size: 12px;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 0;
  color: #909399;
}

.empty-state i {
  font-size: 48px;
  margin-bottom: 15px;
  color: #e4e7ed;
}

.recycle-bin-dialog /deep/ .el-dialog__body {
  padding-top: 10px;
}
</style>
