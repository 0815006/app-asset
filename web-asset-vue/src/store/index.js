import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    // 全局搜索关键字
    globalSearchQuery: '',
    // 热门搜索词列表
    hotKeywords: [],
    // 访问排行榜列表
    globalUseTopList: [],
    // 资产人气榜列表
    globalStarTopList: [],
    // 最新更新列表
    latestUpdatesList: [],
    // 我的收藏列表
    myStarList: [],
    // 最近访问列表
    recentAccessList: [],
    // 产品核心资产列表
    curatedAssets: [],
    // 产品使用榜列表
    productUseTopList: [],
    // 当前活跃的 Tab
    activeTab: 'search-first',
    // 业务版图中的区域视图模式
    zoneViewMode: 'tech',
    // 文件预览相关
    previewVisible: false,
    currentPreviewFile: null,
    currentPreviewTree: [],
    currentPreviewTitle: '',
    // 搜索结果相关
    searchResultVisible: false,
    currentSearchQuery: '',
    searchResults: [],
    // 用户ID (模拟，实际应从认证获取)
    userId: 2
  },
  mutations: {
    SET_GLOBAL_SEARCH_QUERY(state, query) {
      state.globalSearchQuery = query;
    },
    SET_HOT_KEYWORDS(state, keywords) {
      state.hotKeywords = keywords;
    },
    SET_GLOBAL_USE_TOP_LIST(state, list) {
      state.globalUseTopList = list;
    },
    SET_GLOBAL_STAR_TOP_LIST(state, list) {
      state.globalStarTopList = list;
    },
    SET_LATEST_UPDATES_LIST(state, list) {
      state.latestUpdatesList = list;
    },
    SET_MY_STAR_LIST(state, list) {
      state.myStarList = list;
    },
    SET_RECENT_ACCESS_LIST(state, list) {
      state.recentAccessList = list;
    },
    SET_CURATED_ASSETS(state, assets) {
      state.curatedAssets = assets;
    },
    SET_PRODUCT_USE_TOP_LIST(state, list) {
      state.productUseTopList = list;
    },
    SET_ACTIVE_TAB(state, tab) {
      state.activeTab = tab;
    },
    SET_ZONE_VIEW_MODE(state, mode) {
      state.zoneViewMode = mode;
    },
    SET_PREVIEW_VISIBLE(state, visible) {
      state.previewVisible = visible;
    },
    SET_CURRENT_PREVIEW_FILE(state, file) {
      state.currentPreviewFile = file;
    },
    SET_CURRENT_PREVIEW_TREE(state, tree) {
      state.currentPreviewTree = tree;
    },
    SET_CURRENT_PREVIEW_TITLE(state, title) {
      state.currentPreviewTitle = title;
    },
    SET_SEARCH_RESULT_VISIBLE(state, visible) {
      state.searchResultVisible = visible;
    },
    SET_CURRENT_SEARCH_QUERY(state, query) {
      state.currentSearchQuery = query;
    },
    SET_SEARCH_RESULTS(state, results) {
      state.searchResults = results;
    },
    // 更新单个文件的 isNew 状态
    UPDATE_FILE_IS_NEW(state, { fileId, isNew }) {
      const updateFile = (list) => {
        const file = list.find(f => f.id === fileId);
        if (file) {
          file.isNew = isNew;
        }
      };

      updateFile(state.latestUpdatesList);
      updateFile(state.myStarList);
      updateFile(state.recentAccessList);
      updateFile(state.globalUseTopList); // 如果榜单也需要实时更新
      updateFile(state.globalStarTopList); // 如果榜单也需要实时更新
      updateFile(state.curatedAssets); // 如果榜单也需要实时更新
      // 还需要更新 Home.vue 中 techTreeData 和 mgmtTreeData 中的文件
      // 这部分可能需要更复杂的递归更新逻辑，或者在 Home.vue 中直接处理
    }
  },
  actions: {
    // 可以在这里定义异步操作，例如从后端获取数据并提交 mutation
  },
  getters: {
    // 可以在这里定义计算属性，例如过滤后的列表
  }
})