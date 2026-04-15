<template>
  <div class="text-viewer" v-loading="loading">
    <template v-if="isMarkdown">
      <div class="markdown-body" v-html="markdownHtml"></div>
    </template>
    <pre v-else-if="textContent">{{ textContent }}</pre>
    <div v-else-if="!loading" class="empty-text">文件内容为空</div>
  </div>
</template>

<script>
import { getAssetTextContent } from '@/api/asset-node'
import { marked } from 'marked'
import hljs from 'highlight.js'
import 'highlight.js/styles/github.css' // 引用 github 风格的代码高亮样式

export default {
  name: 'TextViewer',
  props: {
    previewUrl: {
      type: String,
      required: true
    },
    fileData: {
      type: Object,
      required: true
    },
    isMarkdown: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      textContent: '',
      loading: false
    }
  },
  computed: {
    markdownHtml() {
      if (!this.textContent) return '';
      
      // 配置 marked 使用 highlight.js
      marked.setOptions({
        highlight: function(code, lang) {
          const language = hljs.getLanguage(lang) ? lang : 'plaintext';
          return hljs.highlight(code, { language }).value;
        },
        langPrefix: 'hljs language-', // 兼容 highlight.js 样式
        breaks: true,
        gfm: true
      });
      
      return marked.parse(this.textContent);
    }
  },
  mounted() {
    this.fetchTextContent();
  },
  watch: {
    fileData: {
      handler(newVal, oldVal) {
        if (newVal && oldVal && newVal.id !== oldVal.id) {
          this.fetchTextContent();
        }
      },
      deep: true
    }
  },
  methods: {
    async fetchTextContent() {
      this.loading = true;
      this.textContent = '';
      try {
        const response = await getAssetTextContent(
          this.fileData.id,
          { userId: localStorage.getItem('userId') }
        );
        this.textContent = response;
      } catch (error) {
        console.error('Fetch text failed', error);
        this.textContent = '获取文件内容出错';
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>

<style scoped>
.text-viewer {
  width: 100%;
  height: 100%;
  background-color: #fff;
  padding: 30px;
  overflow-y: auto;
}

.text-viewer pre {
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: Consolas, Monaco, 'Andale Mono', 'Ubuntu Mono', monospace;
  font-size: 14px;
  line-height: 1.6;
  color: #303133;
}

.empty-text {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #909399;
}

/* Markdown 预览样式 */
.markdown-body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  font-size: 16px;
  line-height: 1.5;
  word-wrap: break-word;
  color: #24292e;
}

.markdown-body h1, .markdown-body h2, .markdown-body h3 {
  margin-top: 24px;
  margin-bottom: 16px;
  font-weight: 600;
  line-height: 1.25;
  border-bottom: 1px solid #eaecef;
  padding-bottom: 0.3em;
}

.markdown-body p {
  margin-top: 0;
  margin-bottom: 16px;
}

.markdown-body code {
  padding: 0.2em 0.4em;
  margin: 0;
  font-size: 85%;
  background-color: rgba(27,31,35,0.05);
  border-radius: 3px;
}

.markdown-body pre {
  padding: 16px;
  overflow: auto;
  font-size: 85%;
  line-height: 1.45;
  background-color: #f6f8fa;
  border-radius: 3px;
  margin-bottom: 16px;
}

.markdown-body pre code {
  display: inline;
  max-width: auto;
  padding: 0;
  margin: 0;
  overflow: visible;
  line-height: inherit;
  word-wrap: normal;
  background-color: transparent;
  border: 0;
}

.markdown-body table {
  border-spacing: 0;
  border-collapse: collapse;
  margin-top: 0;
  margin-bottom: 16px;
  width: 100%;
}

.markdown-body table th, .markdown-body table td {
  padding: 6px 13px;
  border: 1px solid #dfe2e5;
}

.markdown-body table tr {
  background-color: #fff;
  border-top: 1px solid #c6cbd1;
}

.markdown-body table tr:nth-child(2n) {
  background-color: #f6f8fa;
}
</style>
