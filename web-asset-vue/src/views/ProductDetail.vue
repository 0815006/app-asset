<template>
  <div class="product-detail-wrapper" v-loading="loading">
    <!-- 顶部导航栏组件 -->
    <main-header active-tab="business-landscape" />

    <div class="product-detail-container">
      <div class="header">
        <div class="breadcrumb">
          <el-breadcrumb separator-class="el-icon-arrow-right">
            <el-breadcrumb-item :to="{ path: '/', query: { tab: 'business-landscape' } }">业务版图</el-breadcrumb-item>
            <el-breadcrumb-item>产品详情</el-breadcrumb-item>
            <el-breadcrumb-item>{{ product.name }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="local-search">
          <el-input
            placeholder="在当前产品下搜索..."
            v-model="localSearchQuery"
            class="search-input"
            @keyup.enter.native="performSearch(localSearchQuery)"
            clearable>
            <el-button slot="append" icon="el-icon-search" type="primary" @click="performSearch(localSearchQuery)"></el-button>
          </el-input>
        </div>
      </div>

      <div class="main-content">
        <!-- 第一行：产品画像 + 核心资产 -->
        <el-row :gutter="20" class="top-row">
          <el-col :span="8">
            <el-card class="box-card profile-card equal-height">
              <div slot="header" class="clearfix">
                <span>产品画像</span>
                <el-tag size="small" style="float: right;">{{ product.status }}</el-tag>
              </div>
              <div class="profile-info">
                <div class="info-item">
                  <span class="label">产品名称：</span>
                  <span class="value">{{ product.name }} <span v-if="product.code" class="product-code">({{ product.code }})</span></span>
                </div>
                <div class="info-item">
                  <span class="label">所属团队：</span>
                  <span class="value">{{ product.team }}</span>
                </div>
                <div class="info-item">
                  <span class="label">业务领域：</span>
                  <span class="value">{{ product.domain }}</span>
                </div>
                <div class="info-item">
                  <span class="label">负责人：</span>
                  <span class="value">{{ product.owner }}</span>
                </div>
                <div class="info-item">
                  <span class="label">资产总数：</span>
                  <span class="value highlight">{{ product.assetCount }}</span>
                </div>
                <div class="info-item">
                  <span class="label">最近更新：</span>
                  <span class="value">{{ product.updateTime }}</span>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="16">
            <el-card class="box-card curated-card equal-height">
              <div slot="header" class="clearfix">
                <span>产品核心资产</span>
                <el-tag size="small" style="float: right;">新人必读</el-tag>
              </div>
              <product-curated-asset-list :product-id="product.id" @node-click="handleCuratedAssetClick" />
            </el-card>
          </el-col>
        </el-row>

        <!-- 第二行：使用榜 + 资产库 -->
        <el-row :gutter="20" class="middle-row">
          <el-col :span="8">
            <el-card class="box-card ranking-card">
              <div slot="header" class="clearfix">
                <span>产品使用榜</span>
                <el-tag size="small" style="float: right;">活跃度排行</el-tag>
              </div>
              <product-use-ranking-list :product-id="product.id" @node-click="handleUseRankingClick" />
            </el-card>
          </el-col>
          <el-col :span="16">
            <el-card class="box-card assets-card">
              <div slot="header" class="clearfix assets-header">
                <span>文档资产库</span>
                <div class="actions">
                  <el-button type="primary" size="small" icon="el-icon-upload2" @click="showUploadDialog" v-if="hasEditPermission">上传文档</el-button>
                  <el-button size="small" icon="el-icon-download" @click="batchDownload" v-if="hasEditPermission">打包下载</el-button>
                </div>
              </div>

              <el-tree
                :key="treeKey"
                :data="assetTreeData"
                :props="defaultProps"
                :filter-node-method="filterNode"
                ref="assetTree"
                node-key="id"
                lazy
                :load="loadNode"
                :show-checkbox="hasEditPermission"
                @node-click="handleNodeClick"
                class="custom-tree">
                <span class="custom-tree-node" slot-scope="{ node, data }">
                  <span>
                    <i :class="data.nodeType === 1 ? 'el-icon-folder' : 'el-icon-document'"></i>
                    <span>{{ node.label }}</span>
                  </span>
                  <span class="node-actions" v-if="data.nodeType === 1 && hasEditPermission">
                    <el-button type="text" size="mini" icon="el-icon-plus" @click.stop="addSubCategory(node, data)">新建子分类</el-button>
                  </span>
                </span>
              </el-tree>
            </el-card>

            <!-- 知识图谱：放在资产库下方，右侧对齐 -->
            <el-card class="box-card graph-card" style="margin-top: 20px;">
              <div slot="header" class="clearfix">
                <span>知识图谱</span>
              </div>
              <div class="graph-container">
                <el-empty description="知识图谱功能待实现"></el-empty>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>
    </div>

    <!-- 上传弹窗 -->
    <el-dialog title="上传文档" :visible.sync="uploadDialogVisible" width="500px">
      <el-form :model="uploadForm" label-width="100px">
        <el-form-item label="目标分类">
          <el-cascader
            :key="cascaderKey"
            ref="categoryCascader"
            v-model="uploadForm.categoryId"
            :props="cascaderProps"
            popper-class="category-cascader"
            clearable
            placeholder="请选择分类（不选默认进入未分类）"
            style="width: 100%;">
            <template slot-scope="{ node, data }">
              <div class="cascader-node-custom" @click="handleCascaderNodeClick(node)">
                {{ data.fileName }}
              </div>
            </template>
          </el-cascader>
        </el-form-item>
        <el-form-item label="选择文件">
          <el-upload
            class="upload-demo"
            drag
            action="#"
            :auto-upload="false"
            :on-change="handleFileChange"
            :on-remove="handleRemove"
            :file-list="fileList"
            multiple>
            <i class="el-icon-upload"></i>
            <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
            <div class="el-upload__tip" slot="tip">支持同名文件覆盖或版本递增，同时保存至本地与Solr索引库</div>
          </el-upload>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="uploadDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="submitUpload" :loading="loading">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 新建子分类弹窗 -->
    <el-dialog title="新建子分类" :visible.sync="newFolderDialogVisible" width="400px">
      <div style="margin-bottom: 20px; color: #606266;">
        在当前层级目录下（<span style="color: #409EFF; font-weight: bold;">{{ newFolderForm.parentName }}</span>）新增
      </div>
      <el-form :model="newFolderForm" label-width="80px" @submit.native.prevent="submitCreateFolder">
        <el-form-item label="目录名称">
          <el-input v-model="newFolderForm.name" placeholder="请输入目录名称"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="newFolderDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="submitCreateFolder" :loading="dialogLoading" :disabled="dialogLoading">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 超级预览弹窗 -->
    <super-preview 
      :visible.sync="previewVisible" 
      :title="product.name"
      :file-data="currentPreviewFile"
      :tree-data="assetTreeData"
      :can-update="hasEditPermission"
      @node-click="handlePreviewNodeClick"
      @delete-success="refreshRoot">
    </super-preview>

    <!-- 搜索结果弹窗 -->
    <search-result-dialog
      :visible.sync="searchResultVisible"
      :query="currentSearchQuery"
      :results="searchResults"
      :total="searchTotal"
      :loading="searchLoading"
      :current-page="searchPage"
      :page-size="searchPageSize"
      @page-change="handleSearchPageChange"
      @item-click="handleSearchResultClick">
    </search-result-dialog>
  </div>
</template>

<script>
import MainHeader from '../components/MainHeader.vue'
import SuperPreview from '../components/SuperPreview.vue'
import SearchResultDialog from '../components/SearchResultDialog.vue'
import ProductCuratedAssetList from '../components/ProductCuratedAssetList.vue'
import ProductUseRankingList from '../components/ProductUseRankingList.vue'
import { getProductList } from '@/api/product'
import { getAssetTree, uploadFile, createFolder, downloadAssets, getAssetDetails } from '@/api/asset-node'
import { search } from '@/api/search'

export default {
  name: 'ProductDetail',
  components: {
    MainHeader,
    SuperPreview,
    SearchResultDialog,
    ProductCuratedAssetList,
    ProductUseRankingList
  },
  data() {
    return {
      localSearchQuery: '',
      previewVisible: false,
      uploadDialogVisible: false,
      newFolderDialogVisible: false,
      currentPreviewFile: null,
      
      searchResultVisible: false,
      currentSearchQuery: '',
      searchResults: [],
      searchTotal: 0,
      searchPage: 1,
      searchPageSize: 10,
      searchLoading: false,
      curatedAssets: [], // New data property for curated assets
      useRanking: [],    // New data property for use ranking
      
      product: {
        id: this.$route.params.id,
        name: '加载中...',
        code: '',
        team: '',
        domain: '',
        owner: '',
        assetCount: 0,
        updateTime: '',
        status: ''
      },
      
      uploadForm: {
        categoryId: []
      },
      newFolderForm: {
        name: '',
        parentId: 0,
        parentName: ''
      },
      currentNode: null,
      cascaderKey: 0,
      cascaderProps: {
        lazy: true,
        checkStrictly: true,
        value: 'id',
        label: 'fileName',
        lazyLoad: (node, resolve) => {
          this.loadCascaderData(node, resolve);
        }
      },
      fileList: [],
      loading: false,
      dialogLoading: false,
      
      defaultProps: {
        children: 'children',
        label: 'label',
        isLeaf: 'leaf'
      },
      
      assetTreeData: [],
      treeKey: 0,
      currentUser: JSON.parse(localStorage.getItem('userInfo') || '{}')
    }
  },
  computed: {
    hasEditPermission() {
      const isSuperAdmin = this.currentUser && this.currentUser.roleType === 1;
      if (isSuperAdmin) return true;
      
      if (this.currentUser && this.product.ownerIds) {
        const ownerIdList = String(this.product.ownerIds).split(',').map(id => id.trim());
        return ownerIdList.includes(String(this.currentUser.id));
      }
      return false;
    }
  },
  created() {
    this.fetchData();
  },
  methods: {
    async loadCascaderData(node, resolve) {
      const { level, data } = node;
      const parentId = level === 0 ? 0 : data.id;
      try {
        const res = await getAssetTree({ product_id: this.product.id, parent_id: parentId });
        const nodes = (res || [])
          .filter(n => n.nodeType === 1) // Only folders for category selection
          .map(n => ({
            id: n.id,
            fileName: n.fileName,
            leaf: n.subFolderFlag === 0
          }));
        resolve(nodes);
      } catch (e) {
        resolve([]);
      }
    },
    handleCascaderNodeClick(node) {
      this.uploadForm.categoryId = node.path;
      if (!node.isLeaf) {
        node.expand();
      }
    },
    async fetchData() {
      this.loading = true;
      try {
        const productsRes = await getProductList();
        const productData = (productsRes || []).find(p => p.id == this.product.id);
        
        if (productData) {
            this.product = {
              id: productData.id,
              name: productData.productName,
              code: productData.productCode,
              team: productData.teamName,
              domain: productData.domainName,
              owner: productData.ownerName || 'Unknown',
              ownerIds: productData.ownerIds,
              assetCount: productData.assetCount,
              updateTime: productData.updatedAt ? productData.updatedAt.replace('T', ' ') : '',
              status: '活跃'
            };
        }
      } catch (error) {
        console.error(error);
        this.$message.error('加载数据失败');
      } finally {
        this.loading = false;
      }
    },
    async loadNode(node, resolve) {
      if (node.level === 0) {
        try {
          const res = await getAssetTree({ product_id: this.product.id, parent_id: 0 });
          const rootNodes = (res || []).map(n => ({
            ...n,
            label: n.fileName,
            leaf: n.nodeType === 2 || !n.hasChildren
          }));
          this.assetTreeData = rootNodes;
          return resolve(rootNodes);
        } catch (e) {
          return resolve([]);
        }
      }
      if (node.data.hasChildren) {
        try {
          const res = await getAssetTree({ product_id: this.product.id, parent_id: node.data.id });
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
    filterNode(value, data) {
      if (!value) return true;
      return data.label.indexOf(value) !== -1;
    },
    async handleNodeClick(data) {
      if (data.nodeType === 2) {
        this.loading = true;
        try {
          const fileDetails = await getAssetDetails(data.id, { userId: this.currentUser.id });
          this.currentPreviewFile = { ...data, ...fileDetails };
          this.previewVisible = true;
        } catch (e) {
          console.error('Failed to get file details:', e);
          this.currentPreviewFile = data;
          this.previewVisible = true;
        } finally {
          this.loading = false;
        }
      }
    },
    async handlePreviewNodeClick(data) {
      if (data.nodeType === 2) {
        try {
          const fileDetails = await getAssetDetails(data.id, { userId: this.currentUser.id });
          this.currentPreviewFile = { ...data, ...fileDetails };
          this.previewVisible = true;
        } catch (e) {
          this.currentPreviewFile = data;
        }
      }
    },
    async performSearch(query, page = 1) {
      if (!query) {
        this.$message.warning('请输入搜索关键字');
        return;
      }
      
      this.searchLoading = true;
      this.searchPage = page;
      try {
        const res = await search({ 
          keyword: query, 
          productId: this.product.id,
          page: this.searchPage,
          size: this.searchPageSize
        });
        
        let results = [];
        let total = 0;
        if (res && res.list) {
          total = res.total;
          results = res.list.map(item => ({
            id: parseInt(item.id),
            label: item.name,
            fileName: item.name,
            ext: item.ext,
            treePath: item.tree_path,
            productId: item.product_id,
            nodeType: 2,
            isProduct: false,
            path: [this.product.name],
            zoneName: this.product.name,
            context: item.highlight || item.text || '暂无内容预览',
            sourceTree: this.assetTreeData,
            ...item
          }));
        }
        
        this.searchResults = results;
        this.searchTotal = total;
        this.currentSearchQuery = query;
        this.searchResultVisible = true;
      } catch (error) {
        console.error('Search failed:', error);
        this.$message.error('搜索失败，请检查网络或联系管理员');
      } finally {
        this.searchLoading = false;
      }
    },
    handleSearchPageChange(page) {
      this.performSearch(this.currentSearchQuery, page);
    },
    showUploadDialog() {
      this.uploadDialogVisible = true;
      this.fileList = [];
      this.cascaderKey++;
    },
    handleFileChange(file, fileList) {
      this.fileList = fileList;
    },
    handleRemove(file, fileList) {
      this.fileList = fileList;
    },
    async submitUpload() {
      if (this.fileList.length === 0) {
        this.$message.warning('请选择要上传的文件');
        return;
      }
      
      let parentId = 0;
      if (this.uploadForm.categoryId && this.uploadForm.categoryId.length > 0) {
        parentId = this.uploadForm.categoryId[this.uploadForm.categoryId.length - 1];
      }
      
      this.loading = true;
      try {
        for (const file of this.fileList) {
          const formData = new FormData();
          formData.append('file', file.raw);
          formData.append('product_id', this.product.id);
          formData.append('parent_id', parentId);
          
          await uploadFile(formData);
        }
        
        this.$message.success('文件上传成功');
        this.uploadDialogVisible = false;
        this.fileList = [];
        
        const parentNode = this.$refs.assetTree.getNode(parentId);
        if (parentNode) {
          parentNode.data.hasChildren = true;
          parentNode.isLeaf = false;
          parentNode.loaded = false;
          parentNode.expand();
        } else {
          this.refreshRoot();
        }
      } catch (error) {
        console.error(error);
        if (!error.message || error.message.indexOf('timeout') > -1) {
          this.$message.error('上传请求超时或网络异常');
        }
      } finally {
        this.loading = false;
      }
    },
    async batchDownload() {
      const checkedNodes = this.$refs.assetTree.getCheckedNodes();
      if (checkedNodes.length === 0) {
        this.$message.warning('请先勾选需要下载的文件');
        return;
      }
      
      const fileIds = checkedNodes.map(node => node.id);
      
      this.loading = true;
      try {
        const response = await downloadAssets({ file_ids: fileIds });
        const blob = new Blob([response], { type: 'application/zip' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `${this.product.name}_资产打包.zip`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
        this.$message.success(`已成功打包下载 ${checkedNodes.length} 个节点`);
      } catch (error) {
        console.error('下载失败', error);
      } finally {
        this.loading = false;
      }
    },
    addSubCategory(node, data) {
      this.newFolderForm = {
        name: '',
        parentId: data.id,
        parentName: data.fileName
      };
      this.currentNode = node;
      this.newFolderDialogVisible = true;
    },
    async submitCreateFolder() {
      if (this.dialogLoading) return;
      if (!this.newFolderForm.name) {
        this.$message.warning('请输入目录名称');
        return;
      }
      
      this.dialogLoading = true;
      try {
        await createFolder({
          product_id: this.product.id,
          parent_id: this.newFolderForm.parentId,
          folder_name: this.newFolderForm.name
        });
        this.$message.success('创建成功');
        this.newFolderDialogVisible = false;
        if (this.currentNode) {
          this.currentNode.data.hasChildren = true;
          this.currentNode.isLeaf = false;
          this.currentNode.loaded = false;
          this.currentNode.expand();
        } else {
          this.refreshRoot();
        }
      } catch (e) {
        console.error(e);
      } finally {
        this.dialogLoading = false;
      }
    },
    async refreshRoot() {
      try {
        const treeRes = await getAssetTree({ product_id: this.product.id, parent_id: 0 });
        this.assetTreeData = treeRes.data.map(node => ({
          ...node,
          label: node.fileName,
          leaf: node.nodeType === 2 || !node.hasChildren
        }));
        this.treeKey++;
      } catch (e) {
        console.error('刷新列表失败', e);
      }
    },
    async handleSearchResultClick(item) {
      this.loading = true;
      try {
        const fileDetails = await getAssetDetails(item.id, { userId: this.currentUser.id });
        this.currentPreviewFile = { ...item, ...fileDetails };
        this.previewVisible = true;
      } catch (error) {
        console.error('Failed to get file details for preview:', error);
        this.$message.error('无法加载文件预览，请重试');
      } finally {
        this.loading = false;
      }
    },
    // New method for handling curated asset clicks
    async handleCuratedAssetClick(item) {
      this.loading = true;
      try {
        const fileDetails = await getAssetDetails(item.fileId, { userId: this.currentUser.id });
        this.currentPreviewFile = { 
          ...item, 
          ...fileDetails,
          label: fileDetails.fileName || item.fileName 
        };
        this.previewVisible = true;
      } catch (error) {
        console.error('Failed to get curated asset details for preview:', error);
        this.$message.error('无法加载核心资产预览，请重试');
      } finally {
        this.loading = false;
      }
    },
    // New method for handling use ranking clicks
    async handleUseRankingClick(item) {
      this.loading = true;
      try {
        const fileDetails = await getAssetDetails(item.fileId, { userId: this.currentUser.id });
        this.currentPreviewFile = { 
          ...item, 
          ...fileDetails,
          label: fileDetails.fileName || item.fileName 
        };
        this.previewVisible = true;
      } catch (error) {
        console.error('Failed to get use ranking item details for preview:', error);
        this.$message.error('无法加载使用排行项预览，请重试');
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>

<style scoped>
.product-detail-wrapper {
  min-height: 100vh;
  background-color: #f5f7fa;
}

.product-detail-container {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.top-row {
  margin-bottom: 20px;
  display: flex;
}

.middle-row {
  margin-bottom: 20px;
}

.equal-height {
  height: 350px; /* 调整为 350px 以匹配画像内容高度 */
  margin-bottom: 0;
  display: flex;
  flex-direction: column;
}

.curated-card /deep/ .el-card__body {
  flex: 1;
  overflow-y: auto;
  padding: 10px 15px; /* 减小上下内边距 */
}

.profile-card /deep/ .el-card__body {
  flex: 1;
  overflow-y: hidden;
  padding: 15px;
}

.breadcrumb {
  font-size: 16px;
}

.local-search {
  width: 300px;
}

.box-card {
  margin-bottom: 20px;
  border-radius: 8px;
}

.profile-info {
  font-size: 14px;
}

.info-item {
  display: flex;
  align-items: center;
  padding: 10px 0; /* 调整内边距以匹配排行榜行高 */
  border-bottom: 1px dashed #ebeef5;
  height: 42px; /* 固定行高 */
  box-sizing: border-box;
}

.info-item:last-child {
  border-bottom: none;
}

.info-item .label {
  color: #909399;
  width: 80px;
}

.info-item .value {
  color: #303133;
  flex: 1;
}

.info-item .highlight {
  color: #409EFF;
  font-weight: bold;
  font-size: 16px;
}

.product-code {
  color: #909399;
  font-weight: normal;
  font-size: 13px;
  margin-left: 5px;
}

.assets-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.custom-tree {
  margin-top: 10px;
}

.custom-tree-node {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 14px;
  padding-right: 8px;
}

.custom-tree-node i {
  margin-right: 6px;
  color: #909399;
}

.node-actions {
  display: none;
}

.custom-tree-node:hover .node-actions {
  display: inline-block;
}

.graph-container {
  min-height: 20px; /* 高度减半 */
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #f8f9fa;
  border-radius: 4px;
}
</style>

<style>
.category-cascader .el-cascader-panel .el-radio {
  width: 100%;
  height: 100%;
  z-index: 10;
  position: absolute;
  top: 0;
  left: 0;
  display: flex;
  align-items: center;
  pointer-events: none;
}

.category-cascader .el-cascader-panel .el-radio__input {
  margin-left: 10px;
}

.category-cascader .el-cascader-node__label {
  padding-left: 30px;
  width: 100%;
}

.cascader-node-custom {
  width: 100%;
  height: 100%;
  padding-left: 10px;
}

.category-cascader .el-cascader-node__postfix {
  z-index: 11;
}

.category-cascader .el-cascader-node {
  position: relative;
  padding: 0;
}
</style>
