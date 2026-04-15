<template>
  <div class="tab-content">
    <relationship-graph @node-click="handleProductGraphClick"></relationship-graph>
  </div>
</template>

<script>
import RelationshipGraph from '../../components/RelationshipGraph.vue'

export default {
  name: 'RelationshipGraphTab',
  components: {
    RelationshipGraph
  },
  methods: {
    handleProductGraphClick(product) {
      this.$emit('node-click', product);
    }
  }
}
</script>

<style scoped>
.tab-content {
  padding: 10px 0;
}
</style>