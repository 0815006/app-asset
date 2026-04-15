<template>
  <el-dialog
    :visible.sync="localVisible"
    :fullscreen="isFullscreen"
    custom-class="super-preview-dialog"
    :show-close="false"
    append-to-body
    @opened="handleOpened">
    
    <div slot="title" class="preview-header">
      <div class="header-left">
        <i class="el-icon-document"></i>
        <span class="preview-title" :title="fileData ? (fileData.label || fileData.fileName) : ''">
          {{ fileData ? (fileData.label || fileData.fileName) : '文件预览' }}
        </span>
        <!-- 核心文档按钮 -->
        <el-tooltip 
          :content="canUpdate ? (isCurated ? '取消核心' : '设为核心') : '核心资产'" 
          placement="top">
          <i
            v-if="canUpdate || isCurated"
            :class="[isCurated ? 'el-icon-star-on' : 'el-icon-star-off', { 'readonly-icon': !canUpdate }]"
            class="curated-icon"
            @click="canUpdate && toggleCurated()">
          </i>
        </el-tooltip>

        <!-- 收藏按钮 -->
        <el-tooltip :content="isStarred ? '取消收藏' : '收藏文件'" placement="top">
          <i 
            :class="isStarred ? 'el-icon-star-on' : 'el-icon-star-off'" 
            class="star-icon"
            @click="toggleStar">
          </i>
        </el-tooltip>
      </div>
      <div class="header-right">
        <el-button v-if="canUpdate" type="danger" size="small" icon="el-icon-delete" plain @click="handleDelete">删除</el-button>
        <el-button v-if="canUpdate" type="warning" size="small" icon="el-icon-refresh" plain @click="showUpdateDialog">更新</el-button>
        <el-button type="primary" size="small" icon="el-icon-download" plain @click="downloadFile">下载</el-button>
        <el-button size="small" :icon="isFullscreen ? 'el-icon-copy-document' : 'el-icon-full-screen'" @click="toggleFullscreen">
          {{ isFullscreen ? '退出全屏' : '全屏' }}
        </el-button>
        <el-button size="small" icon="el-icon-close" @click="closePreview">关闭</el-button>
      </div>
    </div>

    <div class="preview-body">
      <!-- 左侧目录树 -->
      <div class="preview-sidebar">
        <div class="sidebar-title">{{ title }}</div>
        <el-tree
          :data="treeData"
          :props="defaultProps"
          node-key="id"
          ref="previewTree"
          lazy
          :load="loadNode"
          :default-expanded-keys="expandedKeys"
          :current-node-key="fileData ? fileData.id : null"
          highlight-current
          @node-click="handleNodeClick"
          class="preview-tree">
          <span class="custom-tree-node" slot-scope="{ node, data }">
            <span>
              <i :class="data.nodeType === 1 ? 'el-icon-folder' : 'el-icon-document'"></i>
              <span class="node-label" :title="node.label">{{ node.label }}</span>
            </span>
          </span>
        </el-tree>
      </div>

      <!-- 右侧内容区 -->
      <div class="preview-content">
        <!-- 展示内容顶部标题 (仅针对非 Office 类文档，因为 OnlyOffice 自带标题栏) -->
        <div v-if="fileData && activeType !== 'office' && !fileMissing" class="content-header">
          <span class="content-title">{{ fileData.label || fileData.fileName }}</span>
        </div>

        <div v-if="fileData" :key="fileData.id" class="preview-container">
          <!-- 文件缺失提醒 -->
          <div v-if="fileMissing" class="missing-file-warning">
            <i class="el-icon-error"></i>
            <h3>文件已丢失</h3>
            <p>该文件在服务器物理存储中未找到，请联系管理员核实。</p>
            <div class="file-info-box">
              <p><strong>文件名：</strong>{{ fileData.label || fileData.fileName }}</p>
              <p><strong>文件 ID：</strong>{{ fileData.id }}</p>
            </div>
          </div>

          <template v-else>
            <!-- PDF 预览 -->
            <pdf-viewer v-if="activeType === 'pdf'" :url="previewUrl" />
            
            <!-- 图片预览 -->
            <image-viewer v-else-if="activeType === 'image'" :url="previewUrl" />
            
            <!-- Office 预览 (OnlyOffice) -->
            <office-viewer v-if="activeType === 'office'" :file-data="fileData" :absolute-file-url="absoluteFileUrl" />
            
            <!-- XMind 预览 -->
            <xmind-viewer v-else-if="activeType === 'xmind'" :preview-url="previewUrl" :file-data="fileData" />
            
            <!-- 文本预览 -->
            <text-viewer v-else-if="activeType === 'text'" :preview-url="previewUrl" :file-data="fileData" :is-markdown="isMarkdown" />

            <!-- 不支持预览 -->
            <div v-else-if="activeType === 'unsupported'" class="unsupported-preview">
              <i class="el-icon-warning-outline"></i>
              <p>暂不支持预览，请下载查阅</p>
              <el-button type="primary" size="medium" icon="el-icon-download" @click="downloadFile">立即下载</el-button>
            </div>
          </template>
        </div>
        <div v-else class="empty-state">
          <i class="el-icon-document"></i>
          <p>请在左侧选择要预览的文件</p>
        </div>
      </div>
    </div>

    <!-- 更新文件弹窗 -->
    <update-file-dialog
      :visible.sync="updateDialogVisible"
      :file-data="fileData"
      @update-success="handleUpdateSuccess"
    />
  </el-dialog>
</template>

<script>
import { getAssetTree, downloadAssets, recordReadState, starFile, unstarFile, toggleCuratedStatus, getCuratedStatus, deleteAsset, checkAssetExistence } from '@/api/asset-node'
import PdfViewer from './viewers/PdfViewer.vue'
import ImageViewer from './viewers/ImageViewer.vue'
import OfficeViewer from './viewers/OfficeViewer.vue'
import XmindViewer from './viewers/XmindViewer.vue'
import TextViewer from './viewers/TextViewer.vue'
import UpdateFileDialog from './UpdateFileDialog.vue'

export default {
  name: 'SuperPreview',
  components: {
    PdfViewer,
    ImageViewer,
    OfficeViewer,
    XmindViewer,
    TextViewer,
    UpdateFileDialog
  },
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    title: {
      type: String,
      default: '目录结构'
    },
    fileData: {
      type: Object,
      default: () => null
    },
    treeData: {
      type: Array,
      default: () => []
    },
    canUpdate: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      isFullscreen: false,
      defaultProps: {
        children: 'children',
        label: 'label',
        isLeaf: 'leaf'
      },
      expandedKeys: [],
      fileMissing: false,
      activeType: '', // 当前正在显示的类型：pdf, image, office, xmind, text
      updateDialogVisible: false,
      isStarred: false,
      isCurated: false, // New data property for curated status
      lastRecordedId: null, // 记录上次成功记录阅读状态的文件ID
      currentUser: JSON.parse(localStorage.getItem('userInfo') || '{}')
    }
  },
  computed: {
    localVisible: {
      get() {
        return this.visible;
      },
      set(val) {
        this.$emit('update:visible', val);
      }
    },
    isPdf() {
      if (!this.fileData) return false;
      const ext = String(this.fileData.ext || '').toLowerCase();
      return ext === 'pdf';
    },
    isImage() {
      if (!this.fileData) return false;
      const ext = String(this.fileData.ext || '').toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].includes(ext);
    },
    isText() {
      if (!this.fileData) return false;
      const ext = String(this.fileData.ext || '').toLowerCase();
      const textExtensions = [
        'txt', 'md', 'sql', 'log', 'sh', 'py',
        'json', 'xml', 'java', 'js', 'css',
        'yml', 'yaml', 'properties', 'ini', 'conf', 'env',
        'bat', 'cmd', 'ts', 'vue', 'html',
        'c', 'cpp', 'h', 'go', 'php', 'csv'
      ];
      return textExtensions.includes(ext);
    },
    isOffice() {
      if (!this.fileData) return false;
      const ext = String(this.fileData.ext || '').toLowerCase();
      return ['docx', 'doc', 'xlsx', 'xls', 'pptx', 'ppt', 'pdf'].includes(ext);
    },
    isXmind() {
      if (!this.fileData) return false;
      const ext = String(this.fileData.ext || '').toLowerCase();
      return ext === 'xmind';
    },
    isMarkdown() {
      if (!this.fileData) return false;
      const ext = String(this.fileData.ext || '').toLowerCase();
      return ext === 'md';
    },
    previewUrl() {
      if (!this.fileData) return '';
      const userId = this.currentUser.id || localStorage.getItem('userId') || 2;
      const token = localStorage.getItem('token');
      const tokenParam = token ? `&token=${token}` : '';
      // 使用相对路径，依赖 vue.config.js 的代理配置
      return `/api/assets/${this.fileData.id}/view?userId=${userId}${tokenParam}`;
    },
    absoluteFileUrl() {
      if (!this.fileData) return '';
      // OnlyOffice 需要绝对路径。
      // 优先使用环境变量，如果没有则根据当前页面地址推导（注意：OnlyOffice 在 Docker 中运行，通常需要 host.docker.internal）
      const baseUrl = process.env.VUE_APP_BACKEND_API_BASE || (window.location.protocol + '//' + window.location.hostname + ':8081');
      const userId = this.currentUser.id || localStorage.getItem('userId') || 2;
      const token = localStorage.getItem('token');
      const tokenParam = token ? `&token=${token}` : '';
      return `${baseUrl}/api/assets/${this.fileData.id}/view?userId=${userId}${tokenParam}`;
    }
  },
  watch: {
    visible(val) {
      if (val && this.fileData) {
        this.initPreview();
      }
    },
    fileData: {
      handler(val) {
        if (this.visible && val) {
          this.initPreview();
        }
      },
      deep: true
    }
  },
  methods: {
    async initPreview() {
      this.fileMissing = false;
      const currentId = this.fileData.id;
      
      // 1. 销毁所有旧的编辑器/查看器
      this.activeType = '';
      
      // 2. 设置收藏和核心状态
      this.isStarred = !!this.fileData.isStarred;
      // 如果后端返回了 currentUserStarred 字段，优先使用
      if (this.fileData.currentUserStarred !== undefined) {
        this.isStarred = !!this.fileData.currentUserStarred;
      }
      this.getCuratedStatus();

      // 3. 自动展开目录树
      if (this.fileData.treePath && typeof this.fileData.treePath === 'string') {
        const ids = this.fileData.treePath.split('/').filter(id => id && id !== '0').map(id => parseInt(id));
        this.expandedKeys = ids;
      } else {
        this.expandedKeys = [];
        this.findPathToNode(this.treeData, this.fileData.id, []);
      }
      
      this.$nextTick(() => {
        if (this.$refs.previewTree) {
          this.$refs.previewTree.setCurrentKey(this.fileData.id);
          setTimeout(() => {
            const currentNode = this.$el.querySelector('.is-current');
            if (currentNode) {
              currentNode.scrollIntoView({ block: 'center', behavior: 'smooth' });
            }
          }, 300);
        }
      });

      // 4. 检查文件是否存在
      await this.checkFileExistence();
      
      // 如果在等待期间文件已经切换，则终止当前初始化
      if (this.fileData.id !== currentId) return;

      if (!this.fileMissing) {
        // 5. 确定新的显示类型 (优先使用 Office 模式，以支持 OnlyOffice 预览 PDF)
        if (this.isOffice) this.activeType = 'office';
        else if (this.isPdf) this.activeType = 'pdf';
        else if (this.isImage) this.activeType = 'image';
        else if (this.isXmind) this.activeType = 'xmind';
        else if (this.isText) this.activeType = 'text';
        else this.activeType = 'unsupported';

        // 6. 记录阅读状态并消除 New 标
        this.recordRead();
      }
    },
    async recordRead() {
      if (!this.fileData || this.lastRecordedId === this.fileData.id) return;
      try {
        await recordReadState({ file_id: this.fileData.id, user_id: this.currentUser.id });
        this.lastRecordedId = this.fileData.id;
        // 更新 Vuex 中的状态，实现秒级消除
        if (this.$store) {
          this.$store.commit('UPDATE_FILE_IS_NEW', { fileId: this.fileData.id, isNew: false });
        }
      } catch (e) {
        console.warn('Record read state failed', e);
      }
    },
    async toggleStar() {
      if (!this.fileData) return;
      const fileId = this.fileData.id;
      const userId = this.currentUser.id;
      try {
        if (this.isStarred) {
          await unstarFile(fileId, { userId });
          this.isStarred = false;
          if (this.fileData) {
            this.fileData.isStarred = false;
            this.fileData.currentUserStarred = false;
          }
          this.$message.success('已取消收藏');
        } else {
          await starFile(fileId, { userId });
          this.isStarred = true;
          if (this.fileData) {
            this.fileData.isStarred = true;
            this.fileData.currentUserStarred = true;
          }
          this.$message.success('收藏成功');
        }
        // 通知父组件更新数据（可选，用于同步列表状态）
        this.$emit('star-change', { id: fileId, isStarred: this.isStarred });
      } catch (error) {
        console.error('Toggle star failed', error);
        this.$message.error('操作失败');
      }
    },
    async getCuratedStatus() {
      if (!this.fileData) return;
      const fileId = this.fileData.id;
      const productId = this.fileData.productId || 0;
      try {
        const res = await getCuratedStatus({ fileId, productId });
        this.isCurated = res.isCurated;
      } catch (error) {
        console.error('Get curated status failed', error);
      }
    },
    async checkFileExistence() {
      try {
        await checkAssetExistence(this.fileData.id, { userId: this.currentUser.id });
      } catch (error) {
        if (error.response && error.response.status === 404) {
          this.fileMissing = true;
        }
        console.error('Check file existence failed', error);
      }
    },
    handleOpened() {
      if (this.fileData && this.$refs.previewTree) {
        this.$refs.previewTree.setCurrentKey(this.fileData.id);
      }
    },
    async loadNode(node, resolve) {
      if (node.level === 0) {
        return resolve(this.treeData);
      }
      
      if (node.data.hasChildren) {
        try {
          const res = await getAssetTree({ 
            product_id: node.data.productId, 
            parent_id: node.data.id 
          });
          const children = (res || []).map(n => ({
            ...n,
            label: n.fileName,
            leaf: n.nodeType === 2 || !n.hasChildren
          }));
          resolve(children);
        } catch (e) {
          resolve([]);
        }
      } else {
        resolve([]);
      }
    },
    findPathToNode(nodes, targetId, currentPath) {
      for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        const newPath = [...currentPath, node.id || node.label];
        
        if (node.id === targetId) {
          this.expandedKeys = newPath;
          return true;
        }
        
        if (node.children && node.children.length > 0) {
          if (this.findPathToNode(node.children, targetId, newPath)) {
            return true;
          }
        }
      }
      return false;
    },
    toggleFullscreen() {
      this.isFullscreen = !this.isFullscreen;
    },
    closePreview() {
      this.localVisible = false;
      this.activeType = ''; // 触发子组件销毁
      // Reset fullscreen state when closing
      setTimeout(() => {
        this.isFullscreen = false;
      }, 300);
    },
    handleNodeClick(data) {
      if (data.nodeType === 2) {
        this.$emit('node-click', data);
      }
    },
    async downloadFile() {
      if (!this.fileData) return;
      
      // 直接通过浏览器下载单个文件，不打成压缩包
      const userId = this.currentUser.id || localStorage.getItem('userId') || 2;
      const token = localStorage.getItem('token');
      const tokenParam = token ? `&token=${token}` : '';
      
      // 使用相对路径下载，由开发服务器代理转发。
      // 之前尝试使用绝对路径导致了 host.docker.internal 无法解析的问题。
      const downloadUrl = `/api/assets/${this.fileData.id}/view?download=true&userId=${userId}${tokenParam}`;
      
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.setAttribute('download', this.fileData.label || this.fileData.fileName);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      this.$message.success('开始下载');
    },
    showUpdateDialog() {
      this.updateDialogVisible = true;
    },
    async handleDelete() {
      try {
        await this.$confirm('确定要删除该文件吗？删除后将无法在系统中查看。', '警告', {
          confirmButtonText: '确定删除',
          cancelButtonText: '取消',
          type: 'error',
          confirmButtonClass: 'el-button--danger'
        });
        
        await deleteAsset(this.fileData.id);
        this.$message.success('文件已成功删除');
        
        // 通知父组件刷新列表并关闭当前预览
        this.$emit('delete-success', this.fileData.id);
        this.closePreview();
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Delete failed:', error);
          this.$message.error('删除操作失败');
        }
      }
    },
    handleUpdateSuccess(res) {
      // 刷新当前预览
      this.$emit('node-click', { ...this.fileData, ...res });
    },
    async toggleCurated() {
      if (!this.fileData) return;
      const fileId = this.fileData.id;
      const productId = this.fileData.productId || 0;
      try {
        await toggleCuratedStatus({ fileId, productId, isCurated: !this.isCurated });
        this.isCurated = !this.isCurated;
        this.$message.success(this.isCurated ? '已设为核心文档' : '已取消核心文档');
      } catch (error) {
        console.error('Toggle curated status failed', error);
        this.$message.error('操作失败');
      }
    }
  }
}
</script>

<style>
/* 全局覆盖 dialog 样式以实现沉浸式 */
.super-preview-dialog {
  display: flex;
  flex-direction: column;
  margin-top: 5vh !important;
  height: 90vh;
  border-radius: 8px;
  overflow: hidden;
}

.super-preview-dialog.is-fullscreen {
  margin-top: 0 !important;
  height: 100vh;
  border-radius: 0;
}

.super-preview-dialog .el-dialog__header {
  padding: 0;
  border-bottom: 1px solid #ebeef5;
}

.super-preview-dialog .el-dialog__body {
  padding: 0;
  flex: 1;
  display: flex;
  overflow: hidden;
}
</style>

<style scoped>
.preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background-color: #f8f9fa;
}

.header-left {
  display: flex;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
  color: #303133;
  width: 60%;
}

.header-left i {
  margin-right: 8px;
  color: #409EFF;
}

.preview-title {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.star-icon {
  margin-left: 12px;
  font-size: 20px;
  cursor: pointer;
  color: #c0c4cc;
  transition: all 0.3s;
}

.star-icon.el-icon-star-on {
  color: #f7ba2a;
}

.star-icon:hover {
  transform: scale(1.2);
}

.curated-icon {
  margin-left: 12px;
  font-size: 20px;
  cursor: pointer;
  color: #c0c4cc;
  transition: all 0.3s;
}

.curated-icon.el-icon-star-on {
  color: #f56c6c;
}

.curated-icon.readonly-icon {
  cursor: default;
}

.curated-icon.readonly-icon:hover {
  transform: none;
}

.curated-icon:hover:not(.readonly-icon) {
  transform: scale(1.2);
}

.preview-body {
  display: flex;
  width: 100%;
  height: 100%;
}

.preview-sidebar {
  width: 300px;
  border-right: 1px solid #ebeef5;
  background-color: #fff;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.sidebar-title {
  padding: 15px 20px;
  font-size: 16px;
  font-weight: bold;
  color: #409EFF;
  border-bottom: 1px solid #f0f2f5;
  background-color: #fafafa;
}

.preview-tree {
  flex: 1;
  padding: 10px 0;
}

.preview-content {
  flex: 1;
  background-color: #e9eef3;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  padding: 0;
}

.content-header {
  height: 40px;
  background-color: #fff;
  border-bottom: 1px solid #ebeef5;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 20px;
  flex-shrink: 0;
}

.content-title {
  font-size: 14px;
  font-weight: bold;
  color: #606266;
}

.preview-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.missing-file-warning {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  background-color: #fff;
  color: #F56C6C;
  padding: 40px;
  text-align: center;
}

.missing-file-warning i {
  font-size: 80px;
  margin-bottom: 20px;
}

.missing-file-warning h3 {
  font-size: 24px;
  margin-bottom: 10px;
  color: #303133;
}

.file-info-box {
  margin-top: 30px;
  padding: 20px;
  background-color: #fef0f0;
  border: 1px solid #fde2e2;
  border-radius: 4px;
  text-align: left;
  min-width: 300px;
}

.file-info-box p {
  margin: 5px 0;
  color: #606266;
  font-size: 14px;
}

.unsupported-preview {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  background-color: #fff;
  color: #606266;
}

.unsupported-preview i {
  font-size: 80px;
  color: #E6A23C;
  margin-bottom: 20px;
}

.unsupported-preview p {
  font-size: 18px;
  margin-bottom: 30px;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #909399;
}

.empty-state i {
  font-size: 64px;
  margin-bottom: 20px;
  color: #c0c4cc;
}
</style>
