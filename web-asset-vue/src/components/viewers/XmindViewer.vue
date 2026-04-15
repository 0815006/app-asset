<template>
  <div class="xmind-viewer-wrapper" style="width: 100%; height: 100%; position: relative;">
    <div v-if="loading" class="xmind-loading-overlay">
      <el-progress type="circle" :percentage="downloadProgress" :status="downloadProgress === 100 ? 'success' : null"></el-progress>
      <p class="loading-text">正在加载思维导图...</p>
    </div>
    <div id="xmind-container" class="xmind-viewer"></div>
  </div>
</template>

<script>
import { getAssetPreviewData } from '@/api/asset-node'
import MindMap from 'simple-mind-map'
import xmind from 'simple-mind-map/src/parse/xmind'
import JSZip from 'jszip'
import xmlConvert from 'xml-js'

export default {
  name: 'XmindViewer',
  props: {
    previewUrl: {
      type: String,
      required: true
    },
    fileData: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      mindMap: null,
      loading: false,
      downloadProgress: 0,
      resizeObserver: null,
      resizeTimer: null
    }
  },
  created() {
    // 在组件创建时就注入全局依赖，确保解析引擎能找到它们
    window.JSZip = JSZip;
    window.xmlConvert = xmlConvert;
  },
  mounted() {
    this.initXmindViewer();
    this.initResizeObserver();
  },
  beforeDestroy() {
    this.destroyXmindViewer();
  },
  watch: {
    fileData: {
      handler(newVal, oldVal) {
        if (newVal && oldVal && newVal.id !== oldVal.id) {
          this.destroyXmindViewer();
          this.$nextTick(() => {
            this.initXmindViewer();
            this.initResizeObserver();
          });
        }
      },
      deep: true
    }
  },
  methods: {
    initResizeObserver() {
      if (this.resizeObserver) {
        this.resizeObserver.disconnect();
      }
      this.resizeObserver = new ResizeObserver(() => {
        if (this.resizeTimer) {
          cancelAnimationFrame(this.resizeTimer);
        }
        this.resizeTimer = requestAnimationFrame(() => {
          if (this.mindMap) {
            this.mindMap.resize();
          }
        });
      });
      const container = document.getElementById('xmind-container');
      if (container) {
        this.resizeObserver.observe(container);
      }
    },
    async initXmindViewer() {
      this.loading = true;
      this.downloadProgress = 0;
      try {
        const response = await getAssetPreviewData(
          this.fileData.id,
          { userId: localStorage.getItem('userId') },
          (progressEvent) => {
            if (progressEvent.lengthComputable) {
              this.downloadProgress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
            } else {
              this.downloadProgress = Math.min(this.downloadProgress + 10, 90);
            }
          }
        );
        
        const buffer = response;
        console.log('XMind file buffer received, size:', buffer.byteLength);
        
        // 解析 xmind 文件
        console.log('Starting XMind parsing...');
        
        // 针对旧版 XMind 解析逻辑的健壮性处理：
        // 如果 simple-mind-map 内部报错，尝试手动解析或提供更友好的提示
        let data;
        try {
          data = await xmind.parseXmindFile(buffer);
        } catch (parseError) {
          console.error('Internal parser error:', parseError);
          if (parseError.message.includes('elements')) {
            throw new Error('该 XMind 文件结构过于复杂或版本过旧，暂不支持预览。建议下载后使用 XMind 客户端查看。');
          }
          throw parseError;
        }
        
        console.log('XMind parsed successfully:', data);
        
        const container = document.getElementById('xmind-container');
        if (container) {
          container.innerHTML = '';
          console.log('Initializing MindMap instance...');
          this.mindMap = new MindMap({
            el: container,
            data: data,
            readonly: true
          });
          console.log('MindMap initialized.');
        }
      } catch (e) {
        console.error('XMind preview detailed error:', e);
        this.$message({
          message: e.message || 'XMind 预览失败，请检查文件格式',
          type: 'warning',
          duration: 5000,
          showClose: true
        });
      } finally {
        this.loading = false;
        this.downloadProgress = 0;
      }
    },
    destroyXmindViewer() {
      if (this.resizeTimer) {
        cancelAnimationFrame(this.resizeTimer);
        this.resizeTimer = null;
      }
      if (this.resizeObserver) {
        this.resizeObserver.disconnect();
        this.resizeObserver = null;
      }
      if (this.mindMap) {
        try {
          this.mindMap.destroy();
        } catch (e) {
          console.warn('MindMap destroy failed', e);
        }
        this.mindMap = null;
      }
      
      const xmindContainer = document.getElementById('xmind-container');
      if (xmindContainer) {
        xmindContainer.innerHTML = '';
      }
    }
  }
}
</script>

<style scoped>
.xmind-viewer {
  width: 100%;
  height: 100%;
  background-color: #fff;
}

.xmind-loading-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(255, 255, 255, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 10;
}

.xmind-loading-overlay .loading-text {
  margin-top: 15px;
  color: #606266;
  font-size: 14px;
}
</style>
