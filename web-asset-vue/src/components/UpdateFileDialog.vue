<template>
  <el-dialog
    title="更新文件版本"
    :visible.sync="localVisible"
    width="400px"
    append-to-body>
    <div class="update-info">
      <p>您正在更新：<strong>{{ fileData ? fileData.label : '' }}</strong></p>
      <p class="tip">上传新文件将覆盖原物理文件，并生成新的版本号。</p>
    </div>
    <el-upload
      class="update-upload"
      drag
      action="#"
      :auto-upload="false"
      :on-change="handleUpdateFileChange"
      :limit="1"
      :file-list="updateFileList">
      <i class="el-icon-upload"></i>
      <div class="el-upload__text">将新文件拖到此处，或<em>点击上传</em></div>
    </el-upload>
    <div slot="footer" class="dialog-footer">
      <el-button @click="localVisible = false">取 消</el-button>
      <el-button type="primary" @click="submitUpdate" :loading="updating">确 定</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { updateAsset } from '@/api/asset-node'

export default {
  name: 'UpdateFileDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    fileData: {
      type: Object,
      default: () => null
    }
  },
  data() {
    return {
      updateFileList: [],
      updating: false
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
    }
  },
  watch: {
    visible(val) {
      if (val) {
        this.updateFileList = [];
      }
    }
  },
  methods: {
    handleUpdateFileChange(file, fileList) {
      this.updateFileList = fileList;
    },
    async submitUpdate() {
      if (this.updateFileList.length === 0) {
        this.$message.warning('请选择要上传的新文件');
        return;
      }
      
      const newFile = this.updateFileList[0].raw;
      const originalFileName = this.fileData.fileName || this.fileData.label;
      
      if (newFile.name !== originalFileName) {
        this.$message.error(`文件名不一致！请上传名为 "${originalFileName}" 的文件`);
        return;
      }
      
      this.updating = true;
      try {
        const formData = new FormData();
        formData.append('file', newFile);
        
        const res = await updateAsset(this.fileData.id, formData);
        this.$message.success('文件更新成功');
        this.localVisible = false;
        
        // 触发更新成功事件
        this.$emit('update-success', res);
      } catch (error) {
        console.error('更新失败', error);
      } finally {
        this.updating = false;
      }
    }
  }
}
</script>

<style scoped>
.update-info {
  margin-bottom: 20px;
  color: #606266;
}

.update-info .tip {
  font-size: 12px;
  color: #909399;
  margin-top: 5px;
}

.update-upload {
  text-align: center;
}
</style>
