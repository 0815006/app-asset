<template>
  <el-dialog
    title="存储健康检查"
    :visible.sync="visible"
    width="900px"
    :before-close="handleClose"
    append-to-body
    class="health-check-dialog">
    
    <div class="check-controls">
      <el-form :inline="true" :model="form" size="small" class="controls-form">
        <div class="filter-line">
          <el-form-item label="检查范围">
            <el-select v-model="form.type" placeholder="请选择专区" @change="handleTypeChange" style="width: 180px;">
              <el-option label="测试技术与工艺专区" value="tech_zone"></el-option>
              <el-option label="管理专区" value="mgmt_zone"></el-option>
              <el-option label="产品专区" value="product_zone"></el-option>
            </el-select>
          </el-form-item>
          
          <el-form-item v-if="form.type === 'product_zone'" label="选择产品">
            <el-select v-model="form.productId" placeholder="请选择产品" filterable style="width: 200px;">
              <el-option
                v-for="item in products"
                :key="item.id"
                :label="item.productName"
                :value="item.id">
              </el-option>
            </el-select>
          </el-form-item>
          
          <el-form-item>
            <el-button type="primary" @click="startCheck" :loading="checking">开始检查</el-button>
          </el-form-item>
        </div>

        <div v-if="form.type" class="path-line">
          <el-form-item class="path-item">
            <div class="path-container">
              <span class="path-label">存储根目录：</span>
              <el-tag size="medium" class="path-tag">
                <i class="el-icon-folder"></i>
                {{ currentPath || '正在获取...' }}
              </el-tag>
              <el-button 
                type="success" 
                size="mini" 
                icon="el-icon-folder-add" 
                class="create-btn"
                @click="handleCreateRootDir">建根目录</el-button>
              <el-button 
                v-if="form.type === 'product_zone'"
                type="warning" 
                size="mini" 
                icon="el-icon-s-grid" 
                class="init-btn"
                style="margin-left: 10px;"
                :loading="initLoading"
                @click="handleInitFolders">铺底基础五目录</el-button>
              <el-button 
                v-if="form.type === 'tech_zone' || form.type === 'mgmt_zone'"
                type="warning" 
                size="mini" 
                icon="el-icon-s-grid" 
                class="init-btn"
                style="margin-left: 10px;"
                :loading="initLoading"
                @click="handleInitZoneFolders">铺底基础目录</el-button>
            </div>
          </el-form-item>
        </div>
      </el-form>
    </div>

    <div class="check-legend" v-if="checkResult">
      <span class="legend-item"><i class="dot normal"></i> 匹配一致</span>
      <span class="legend-item"><i class="dot missing"></i> 文件丢失 (数据库有，本地无)</span>
      <span class="legend-item"><i class="dot extra"></i> 待入库数据 (本地有，数据库无)</span>
    </div>

    <div class="check-result-container" v-loading="checking">
      <el-empty v-if="!checkResult && !checking" description="请选择范围并开始检查"></el-empty>
      
      <el-tree
        v-if="checkResult"
        :data="[checkResult]"
        :props="defaultProps"
        default-expand-all
        :expand-on-click-node="false"
        class="health-tree">
        <span class="custom-tree-node" slot-scope="{ data }">
          <span :class="['node-content', data.status]">
            <i :class="data.nodeType === 1 ? 'el-icon-folder' : 'el-icon-document'"></i>
            <span class="node-name">{{ data.name }}</span>
            
            <el-tooltip v-if="data.status === 'missing'" content="文件缺失" placement="top">
              <i class="el-icon-warning missing-icon"></i>
            </el-tooltip>
            
            <el-tag v-if="data.status === 'extra'" size="mini" type="success" effect="plain" class="extra-tag">待入库</el-tag>
          </span>
        </span>
      </el-tree>
    </div>

    <div slot="footer" class="dialog-footer" style="display: flex; justify-content: flex-start; align-items: center; width: 100%;">
      <div class="footer-left" style="flex: 1; display: flex; align-items: center;">
        <el-tooltip 
          v-if="hasExtraFiles && !syncing" 
          content="检测到存储空间存在未登记的新文件或目录。点击「一键入库」可将这些待铺底数据自动注册至数据库，并同步建立全文检索索引。" 
          placement="top" 
          effect="dark">
          <el-button type="success" icon="el-icon-upload" @click="handleSyncExtra">一键入库</el-button>
        </el-tooltip>
        
        <div v-if="syncing" style="flex: 1; margin-left: 10px; display: flex; align-items: center;">
          <span style="font-size: 13px; color: #606266; margin-right: 10px; white-space: nowrap;">
            入库进度: {{ syncProgress.processedFiles }} / {{ syncProgress.totalFiles }}
          </span>
          <el-progress 
            :percentage="syncPercentage" 
            :status="syncProgress.errorMsg ? 'exception' : (syncPercentage === 100 ? 'success' : null)"
            style="flex: 1; margin-right: 10px;">
          </el-progress>
          <span style="font-size: 12px; color: #909399; white-space: nowrap; max-width: 200px; overflow: hidden; text-overflow: ellipsis;" :title="syncProgress.currentFileName">
            正在处理: {{ syncProgress.currentFileName }}
          </span>
        </div>
      </div>
    </div>
  </el-dialog>
</template>

<script>
import { getProductList, initProductFolders, initZoneFolders } from '@/api/product'
import { 
  getStoragePath, 
  createRootDir, 
  healthCheck, 
  syncExtra, 
  getSyncProgress 
} from '@/api/asset-node'

export default {
  name: 'StorageHealthCheckDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      form: {
        type: 'tech_zone',
        productId: null
      },
      currentPath: '',
      products: [],
      checking: false,
      syncing: false,
      initLoading: false,
      syncTimer: null,
      syncProgress: {
        totalFiles: 0,
        processedFiles: 0,
        currentFileName: '',
        errorMsg: null
      },
      checkResult: null,
      defaultProps: {
        children: 'children',
        label: 'name'
      }
    }
  },
  computed: {
    hasExtraFiles() {
      if (!this.checkResult) return false;
      return this.checkNodeForExtra(this.checkResult);
    },
    syncPercentage() {
      if (this.syncProgress.totalFiles === 0) return 0;
      const percent = Math.floor((this.syncProgress.processedFiles / this.syncProgress.totalFiles) * 100);
      return percent > 100 ? 100 : percent;
    }
  },
  watch: {
    visible(val) {
      if (val) {
        this.fetchProducts();
        this.fetchStoragePath();
      }
    },
    'form.type': {
      handler() {
        this.fetchStoragePath();
      }
    },
    'form.productId': {
      handler() {
        this.fetchStoragePath();
      }
    }
  },
  beforeDestroy() {
    this.clearSyncTimer();
  },
  methods: {
    async fetchStoragePath() {
      if (!this.form.type) return;
      if (this.form.type === 'product_zone' && !this.form.productId) {
        this.currentPath = '';
        return;
      }
      try {
        const data = await getStoragePath({
          type: this.form.type,
          product_id: this.form.productId
        });
        this.currentPath = data;
      } catch (e) {
        console.error(e);
      }
    },
    async handleCreateRootDir() {
      if (this.form.type === 'product_zone' && !this.form.productId) {
        this.$message.warning('请先选择产品');
        return;
      }
      try {
        await createRootDir({
          type: this.form.type,
          product_id: this.form.productId
        });
        this.$message.success('根目录创建成功');
      } catch (e) {
        // request.js 已经处理了错误弹窗（包括“已经存在”的提示）
        console.error(e);
      }
    },
    async handleInitFolders() {
      if (!this.form.productId) {
        this.$message.warning('请先选择产品');
        return;
      }
      this.initLoading = true;
      try {
        const res = await initProductFolders(this.form.productId);
        this.$message.success(res);
        // 初始化目录后，自动触发一次检查以刷新视图
        this.startCheck();
      } catch (error) {
        console.error("Failed to init folders:", error);
        this.$message.error("铺底基础五目录失败");
      } finally {
        this.initLoading = false;
      }
    },
    async handleInitZoneFolders() {
      this.initLoading = true;
      try {
        const res = await initZoneFolders(this.form.type);
        this.$message.success(res);
        // 初始化目录后，自动触发一次检查以刷新视图
        this.startCheck();
      } catch (error) {
        console.error("Failed to init zone folders:", error);
        this.$message.error("铺底基础目录失败");
      } finally {
        this.initLoading = false;
      }
    },
    async fetchProducts() {
      try {
        const res = await getProductList();
        this.products = res || [];
      } catch (e) {
        console.error(e);
      }
    },
    handleTypeChange() {
      this.form.productId = null;
      this.checkResult = null;
    },
    async startCheck() {
      if (this.form.type === 'product_zone' && !this.form.productId) {
        this.$message.warning('选择具体产品');
        return;
      }
      
      this.checking = true;
      this.checkResult = null;
      try {
        const data = await healthCheck({
          type: this.form.type,
          product_id: this.form.productId
        });
        this.checkResult = data;
      } catch (e) {
        console.error(e);
        // request.js 已经处理了错误弹窗
      } finally {
        this.checking = false;
      }
    },
    handleClose() {
      this.clearSyncTimer();
      this.$emit('update:visible', false);
    },
    checkNodeForExtra(node) {
      if (node.status === 'extra') return true;
      if (node.children && node.children.length > 0) {
        return node.children.some(child => this.checkNodeForExtra(child));
      }
      return false;
    },
    async handleSyncExtra() {
      this.syncing = true;
      this.syncProgress = {
        totalFiles: 0,
        processedFiles: 0,
        currentFileName: '准备中...',
        errorMsg: null
      };
      
      try {
        await syncExtra({
          type: this.form.type,
          product_id: this.form.productId
        });
        
        // 开始轮询进度
        this.pollSyncProgress();
      } catch (e) {
        console.error(e);
        this.syncing = false;
      }
    },
    pollSyncProgress() {
      this.clearSyncTimer();
      this.syncTimer = setInterval(async () => {
        try {
          const data = await getSyncProgress({
            type: this.form.type,
            product_id: this.form.productId
          });
          
          if (data) {
            this.syncProgress.totalFiles = data.totalFiles || 0;
            this.syncProgress.processedFiles = data.processedFiles || 0;
            this.syncProgress.currentFileName = data.currentFileName || '';
            this.syncProgress.errorMsg = data.errorMsg;
            
            if (data.isFinished) {
              this.clearSyncTimer();
              if (data.errorMsg) {
                this.$message.error(data.errorMsg);
              } else {
                this.$message.success('一键入库成功！');
                // 重新检查以刷新树
                this.startCheck();
              }
              setTimeout(() => {
                this.syncing = false;
              }, 1000);
            }
          }
        } catch (e) {
          console.error('获取进度失败', e);
          this.clearSyncTimer();
          this.syncing = false;
        }
      }, 1000); // 每秒轮询一次
    },
    clearSyncTimer() {
      if (this.syncTimer) {
        clearInterval(this.syncTimer);
        this.syncTimer = null;
      }
    }
  }
}
</script>

<style scoped>
.health-check-dialog /deep/ .el-dialog__body {
  padding-top: 10px;
}

.check-controls {
  border-bottom: 1px solid #ebeef5;
  margin-bottom: 15px;
  padding-bottom: 5px;
}

.controls-form {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.filter-line {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.path-line {
  width: 100%;
  margin-top: 10px;
}

.path-item {
  width: 100%;
  margin-right: 0 !important;
}

.path-item /deep/ .el-form-item__content {
  width: 100%;
}

.path-container {
  display: flex;
  align-items: center;
  background-color: #f8f9fa;
  padding: 0 10px;
  border-radius: 4px;
  border: 1px dashed #dcdfe6;
  width: 100%;
}

.path-label {
  font-size: 13px;
  color: #909399;
  white-space: nowrap;
}

.path-tag {
  background-color: transparent;
  border: none;
  color: #409EFF;
  font-family: monospace;
  font-weight: bold;
  max-width: 400px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.create-btn {
  margin-left: auto;
}

.check-legend {
  margin-bottom: 15px;
  font-size: 13px;
  color: #606266;
}

.legend-item {
  margin-right: 20px;
  display: inline-flex;
  align-items: center;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-right: 5px;
}

.dot.normal { background-color: #00a854; }
.dot.missing { background-color: #909399; }
.dot.extra { background-color: #E1F3D8; border: 1px solid #67C23A; }

.check-result-container {
  min-height: 400px;
  max-height: 600px;
  overflow-y: auto;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 15px;
}

.health-tree {
  background: transparent;
}

.custom-tree-node {
  flex: 1;
}

.node-content {
  display: flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 4px;
}

.node-content.normal {
  color: #00a854;
  font-weight: 600;
}

.node-content.missing {
  color: #909399;
  text-decoration: line-through;
}

.node-content.extra {
  background-color: #F0F9EB;
  color: #67C23A;
  font-style: italic;
}

.node-name {
  margin-left: 8px;
  margin-right: 8px;
}

.missing-icon {
  color: #F56C6C;
  font-weight: bold;
}

.extra-tag {
  margin-left: 10px;
}
</style>
