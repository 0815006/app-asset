<template>
  <div>
    <div class="zone-header" v-if="showHeader">
      <span>测试管理专区</span>
      <div class="header-actions">
        <el-button 
          v-if="canManage"
          type="primary" 
          size="small" 
          icon="el-icon-upload2" 
          @click="showUploadDialog">上传文档</el-button>
        <el-input
          placeholder="专区内搜索..."
          :value="searchQuery"
          @input="$emit('update:searchQuery', $event)"
          size="small"
          style="width: 300px;"
          @keyup.enter.native="$emit('search', searchQuery)"
          clearable>
          <el-button slot="append" icon="el-icon-search" @click="$emit('search', searchQuery)"></el-button>
        </el-input>
      </div>
    </div>
      <el-tree
        :key="treeKey"
        :data="treeData"
        :props="defaultProps"
        ref="tree"
        lazy
        :load="loadNode"
        @node-click="handleNodeClick"
        class="custom-tree">
        <span class="custom-tree-node" slot-scope="{ node, data }">
          <span>
            <i :class="data.nodeType === 1 ? 'el-icon-folder' : 'el-icon-document'"></i>
            {{ node.label }}
          </span>
          <span class="node-actions" v-if="data.nodeType === 1 && canManage">
            <el-button type="text" size="mini" icon="el-icon-plus" @click.stop="addSubCategory(node, data)">新建子目录</el-button>
          </span>
        </span>
      </el-tree>

      <!-- 上传弹窗 -->
      <el-dialog title="上传文档 (测试管理专区)" :visible.sync="uploadDialogVisible" width="500px" append-to-body>
        <el-form :model="uploadForm" label-width="100px">
          <el-form-item label="目标分类">
            <el-cascader
              :key="cascaderKey"
              v-model="uploadForm.categoryId"
              :props="cascaderProps"
              popper-class="category-cascader"
              clearable
              placeholder="请选择分类（不选默认进入根目录）"
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
              <div class="el-upload__tip" slot="tip">支持同名文件覆盖或版本递增</div>
            </el-upload>
          </el-form-item>
        </el-form>
        <div slot="footer" class="dialog-footer">
          <el-button @click="uploadDialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="submitUpload" :loading="uploading">确 定</el-button>
        </div>
      </el-dialog>

      <!-- 新建子目录弹窗 -->
      <el-dialog title="新建子目录" :visible.sync="newFolderDialogVisible" width="400px" append-to-body>
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
    </div>
  </template>

<script>
import { getAssetTree, uploadFile, createFolder } from '@/api/asset-node'

export default {
  name: 'MgmtZoneContent',
  props: {
    searchQuery: {
      type: String,
      default: ''
    },
    treeData: {
      type: Array,
      default: () => []
    },
    rootId: {
      type: [Number, String],
      default: null
    },
    defaultProps: {
      type: Object,
      default: () => ({})
    },
    showHeader: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      treeKey: 0,
      uploadDialogVisible: false,
      newFolderDialogVisible: false,
      uploading: false,
      dialogLoading: false,
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
      uploadCategoryOptions: [],
      currentUser: JSON.parse(localStorage.getItem('userInfo') || '{}')
    }
  },
  computed: {
    canManage() {
      return this.currentUser && (this.currentUser.roleType === 1 || this.currentUser.roleType === 2);
    }
  },
  watch: {
    treeData: {
      handler() {
        this.treeKey++;
      },
      deep: true
    }
  },
  methods: {
    async loadNode(node, resolve) {
      if (node.level === 0) {
        return resolve(this.treeData);
      }
      if (node.data.hasChildren) {
        try {
          const res = await getAssetTree({ product_id: 0, parent_id: node.data.id });
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
    handleNodeClick(data, node, component) {
      this.$emit('node-click', data, node, component);
    },
    async loadCascaderData(node, resolve) {
      const { level, data } = node;
      const parentId = level === 0 ? this.rootId : data.id;
      try {
        const res = await getAssetTree({ product_id: 0, parent_id: parentId });
        const nodes = (res || [])
          .filter(n => n.nodeType === 1)
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
    async showUploadDialog() {
      this.uploadDialogVisible = true;
      this.fileList = [];
      this.uploadForm.categoryId = [];
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
      
      let parentId = this.rootId;
      if (this.uploadForm.categoryId && this.uploadForm.categoryId.length > 0) {
        parentId = this.uploadForm.categoryId[this.uploadForm.categoryId.length - 1];
      }
      
      this.uploading = true;
      try {
        for (const file of this.fileList) {
          const formData = new FormData();
          formData.append('file', file.raw);
          formData.append('product_id', 0);
          formData.append('parent_id', parentId);
          formData.append('zone_type', 'mgmt'); // 添加区域类型
          
          await uploadFile(formData);
        }
        
        this.$message.success('文件上传成功');
        this.uploadDialogVisible = false;
        this.fileList = [];
        
        // 局部刷新
        const parentNode = this.$refs.tree.getNode(parentId);
        if (parentNode) {
          parentNode.data.hasChildren = true;
          parentNode.isLeaf = false;
          parentNode.loaded = false;
          parentNode.expand();
        } else {
          this.$emit('refresh');
        }
      } catch (error) {
        console.error(error);
      } finally {
        this.uploading = false;
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
          product_id: 0,
          parent_id: this.newFolderForm.parentId,
          folder_name: this.newFolderForm.name
        });
        this.$message.success('创建成功');
        this.newFolderDialogVisible = false;
        
        // 局部刷新
        if (this.currentNode) {
          this.currentNode.data.hasChildren = true;
          this.currentNode.isLeaf = false;
          this.currentNode.loaded = false;
          this.currentNode.expand();
        } else {
          this.$emit('refresh');
        }
      } catch (e) {
        console.error(e);
      } finally {
        this.dialogLoading = false;
      }
    }
  }
}
</script>

<style scoped>
.zone-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
  font-size: 18px;
  color: #303133;
  margin-bottom: 16px;
}

.header-actions {
  display: flex;
  align-items: center;
}

.header-actions .el-button {
  margin-right: 12px;
}

.custom-tree {
  background: transparent;
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

.cascader-node-custom {
  width: 100%;
  height: 100%;
  padding-left: 10px;
}
</style>

<style>
/* 让级联选择器在任意一级都可以点击文字选中 */
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
.category-cascader .el-cascader-node__postfix {
  z-index: 11;
}
.category-cascader .el-cascader-node {
  position: relative;
  padding: 0;
}
</style>
