# 发布说明

## 版本 1.1.0 - 2026-03-27

### 新功能

*   **业务全景图重构**：引入了“专区”概念，通过单选按钮在“测试技术与工艺专区”、“产品专区”和“测试管理专区”之间快速切换。
*   **管理员管理套件**：
    *   **产品信息维护**：新增了 `ProductMgmtDialog`，支持管理员对产品信息进行增删改查。
    *   **健康检查工具**：集成了“存储健康检查”和“索引健康检查”对话框，用于监控系统底层状态。
    *   **回收站功能**：新增了 `RecycleBinDialog`，支持已删除资产的查看与恢复。
*   **安全登录增强**：
    *   集成了 `CryptoJS`，在登录时对密码进行 AES 加密和 MD5 哈希处理，确保传输安全。
    *   支持通过 URL 参数 (`t_u`, `t_p`) 实现自动登录功能。
*   **导航与布局优化**：
    *   重新设计了首页布局，采用四种核心探索模式：智能探索（Search First）、业务全景（Business Landscape）、关系图谱（Relationship Graph）和任务驱动（Task Driven）。
*   **权限控制细化**：
    *   实现了基于 `roleType` 的 UI 动态展示，管理员可看到专属管理按钮。
    *   细化了文件编辑权限逻辑，支持根据产品负责人和专区管理员身份动态判断。
*   **搜索功能升级**：支持按专区（技术/管理）进行范围搜索，并集成了搜索结果的高亮显示。

### 改进

*   **动态树加载优化**：优化了资产树的加载逻辑，支持根据不同专区和产品动态获取完整的目录结构。
*   **工具类扩展**：新增了 `utils/crypto.js`，统一管理前端加密逻辑。
*   **API 接口扩展**：新增了 `api/asset-node.js`，用于处理更细粒度的资产节点操作。

## 版本 1.0.0 - 2026-03-21

### 新功能

*   **前端框架初始化**：基于 Vue 2 和 Element UI 构建了前端项目，并使用 Vue CLI 进行开发。
*   **用户认证与页面路由**：实现了用户登录 (`Login.vue`)、全局路由管理 (`src/router/index.js`) 和导航功能。
*   **修改密码功能**：新增了修改密码对话框 (`ChangePasswordDialog.vue`)，支持用户自主更新密码。
*   **强制重新登录机制**：在成功修改密码后，系统会自动清除本地会话并跳转至登录页，确保账户安全。
*   **API 接口集成**：通过 Axios (`src/utils/request.js`) 封装了后端 API 请求，并在 `src/api/` 目录下集中管理接口调用。
*   **首页与多标签页**：设计了功能丰富的首页 (`Home.vue`)，包含业务概览 (`BusinessLandscapeTab.vue`)、关系图谱 (`RelationshipGraphTab.vue`)、搜索 (`SearchFirstTab.vue`) 和任务驱动 (`TaskDrivenTab.vue`) 等多个标签页。
*   **资产展示与管理**：开发了资产项 (`AssetItem.vue`)、精选资产列表 (`ProductCuratedAssetList.vue`) 和文件更新对话框 (`UpdateFileDialog.vue`) 等组件。
*   **搜索与结果展示**：实现了热门搜索列表 (`HotSearchList.vue`) 和搜索结果对话框 (`SearchResultDialog.vue`)，提升用户搜索体验。
*   **数据列表与排名**：提供了多种数据展示列表，包括全局收藏榜 (`GlobalStarTopList.vue`)、全局使用榜 (`GlobalUseTopList.vue`)、最新更新列表 (`LatestUpdatesList.vue`)、我的收藏 (`MyStarList.vue`)、产品使用排名 (`ProductUseRankingList.vue`) 和最近访问列表 (`RecentAccessList.vue`)。
*   **多媒体预览功能**：集成了超级预览组件 (`SuperPreview.vue`)，支持图片 (`ImageViewer.vue`)、Office 文档 (`OfficeViewer.vue`)、PDF (`PdfViewer.vue`)、文本 (`TextViewer.vue`) 和 XMind 文件 (`XmindViewer.vue`) 等多种文件类型的在线预览。
*   **产品详情页**：开发了独立的产品详情页面 (`ProductDetail.vue`)，用于展示产品详细信息。

### Bug 修复

*   **修复 API 路径冗余**：解决了由于 `baseURL` 与 API 路径重复导致的双重 `/api/` 请求问题。
*   **修复修改密码提示逻辑**：修正了 `ChangePasswordDialog.vue` 中对响应码的错误判断，确保成功提示能正常弹出。
*   **修复 Vue 警告**：解决了 `MainHeader.vue` 中 `localActiveTab` 属性重复定义的警告。

### 改进

*   **规范化 API 调用**：统一了所有 API 服务文件的路径定义，移除了冗余前缀，增强了代码的可维护性。
*   **统一请求拦截**：在 `src/utils/request.js` 中配置了 Axios 请求和响应拦截器，统一处理错误提示和数据格式。
*   **全局状态管理**：引入 Vuex (`src/store/index.js`) 进行应用级状态管理。
*   **组件化开发**：大量可复用组件的开发，提高了代码的模块化和可维护性。
*   **跨域配置**：通过 `vue.config.js` 配置 `devServer.proxy`，实现前后端接口联调的跨域处理。