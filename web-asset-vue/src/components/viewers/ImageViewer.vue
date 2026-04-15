<template>
  <div class="image-viewer">
    <el-image 
      :src="imageUrl" 
      fit="contain"
      :preview-src-list="[imageUrl]">
    </el-image>
  </div>
</template>

<script>
export default {
  name: 'ImageViewer',
  props: {
    url: {
      type: String,
      required: true
    }
  },
  computed: {
    imageUrl() {
      return this.url;
    }
  }
}
</script>

<style scoped>
.image-viewer {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f2f5;
  padding: 20px;
}

.image-viewer .el-image {
  max-width: 100%;
  max-height: 100%;
  box-shadow: 0 2px 12px 0 rgba(0,0,0,0.1);
}
</style>
