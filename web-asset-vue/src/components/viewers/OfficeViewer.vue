<template>
  <div class="office-viewer-wrapper" style="width: 100%; height: 100%;">
    <div id="office-editor-container" class="office-viewer"></div>
  </div>
</template>

<script>
export default {
  name: 'OfficeViewer',
  props: {
    fileData: {
      type: Object,
      required: true
    },
    absoluteFileUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      docEditor: null
    }
  },
  mounted() {
    this.initOfficeEditor();
  },
  beforeDestroy() {
    this.destroyOfficeEditor();
  },
  watch: {
    fileData: {
      handler(newVal, oldVal) {
        if (newVal && oldVal && newVal.id !== oldVal.id) {
          this.destroyOfficeEditor();
          this.$nextTick(() => {
            this.initOfficeEditor();
          });
        }
      },
      deep: true
    }
  },
  methods: {
    initOfficeEditor() {
      if (typeof DocsAPI === 'undefined') {
        this.$message.error('OnlyOffice SDK 未加载，请检查网络或 Docker 服务状态');
        return;
      }

      const ext = String(this.fileData.ext || '').toLowerCase();
      let documentType = 'word';
      if (['xlsx', 'xls', 'csv'].includes(ext)) documentType = 'cell';
      if (['pptx', 'ppt'].includes(ext)) documentType = 'slide';

      try {
        this.docEditor = new DocsAPI.DocEditor("office-editor-container", {
          "document": {
            "fileType": ext,
            "key": "file_" + this.fileData.id + "_" + new Date().getTime(), // 增加时间戳防止缓存
            "title": this.fileData.label,
            "url": this.absoluteFileUrl,
            "permissions": {
              "comment": false,
              "download": true, // 允许下载
              "edit": false,    // 禁止编辑
              "fillForms": false,
              "print": true,    // 允许打印
              "review": false,
              "chat": false     // 将 chat 移到 permissions 中
            }
          },
          "documentType": documentType,
          "editorConfig": {
            "lang": "zh-CN",
            "mode": "view", // 默认只读预览模式
            "user": {
              "id": localStorage.getItem('userId') || "visitor",
              "name": localStorage.getItem('userName') || "访客"
            },
            "callbackUrl": this.absoluteFileUrl.replace('/view', '/callback'),
            "customization": {
              "autosave": false,
              "comments": false,
              "help": false,
              "hideRightMenu": false,
              "toolbar": true,
              "header": true,
              "plugins": false, // 隐藏插件菜单
              "macros": false   // 隐藏宏
            }
          },
          "height": "100%",
          "width": "100%"
        });
      } catch (e) {
        console.error('OnlyOffice init failed', e);
        this.$message.error('Office 预览初始化失败');
      }
    },
    destroyOfficeEditor() {
      if (this.docEditor) {
        try {
          this.docEditor.destroyEditor();
        } catch (e) {
          console.warn('OnlyOffice destroy failed', e);
        }
        this.docEditor = null;
      }
      // 强制清空容器，防止残留的 iframe 导致卡顿
      const container = document.getElementById('office-editor-container');
      if (container) {
        container.innerHTML = '';
      }
    }
  }
}
</script>

<style scoped>
.office-viewer {
  width: 100%;
  height: 100%;
  background-color: #fff;
}
</style>
