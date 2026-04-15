// 设置 OnlyOffice API 默认地址
process.env.VUE_APP_ONLYOFFICE_API = process.env.VUE_APP_ONLYOFFICE_API || 'http://localhost:9010/web-apps/apps/api/documents/api.js';

const { defineConfig } = require('@vue/cli-service')

module.exports = defineConfig({
  transpileDependencies: true,
  configureWebpack: {
    resolve: {
      fallback: {
        "stream": require.resolve("stream-browserify")
      }
    }
  },
  devServer: {
    port: 9001,
    host: '0.0.0.0',
    allowedHosts: 'all',
    client: {
      webSocketURL: 'auto://0.0.0.0:0/ws',
    },
    proxy: {
      '/api': {
        target: 'http://localhost:8081',
        changeOrigin: true
      }
    }
  }
})
