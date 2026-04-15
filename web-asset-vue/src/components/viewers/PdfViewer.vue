<template>
  <div class="pdf-viewer-wrapper">
    <iframe
      :src="pdfUrl"
      width="100%"
      height="100%"
      frameborder="0"
      class="pdf-viewer">
    </iframe>
  </div>
</template>

<script>
export default {
  name: 'PdfViewer',
  props: {
    url: {
      type: String,
      required: true
    }
  },
  computed: {
    pdfUrl() {
      return this.url;
    }
  }
}
</script>

<style scoped>
.pdf-viewer-wrapper, .pdf-viewer {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
