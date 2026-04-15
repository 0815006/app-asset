<template>
  <div class="relationship-graph">
    <el-empty description="资产拓扑图功能待实现"></el-empty>
    <!-- 这里将集成图表库，例如 G6 或 ECharts -->
    <!-- 点击球体节点（产品），侧滑窗展示该产品的 [8. 产品使用榜] -->
    <el-dialog
      :visible.sync="productUseTopVisible"
      :title="currentProductUseTopTitle"
      width="30%"
      append-to-body>
      <product-use-top-list :product-id="currentProductUseTopId" @node-click="handleProductUseTopClick"></product-use-top-list>
    </el-dialog>
  </div>
</template>

<script>
import ProductUseTopList from './ProductUseTopList.vue'; // 导入产品使用榜组件

export default {
  name: 'RelationshipGraph',
  components: {
    ProductUseTopList
  },
  data() {
    return {
      productUseTopVisible: false,
      currentProductUseTopTitle: '',
      currentProductUseTopId: null
    };
  },
  methods: {
    handleProductGraphClick(product) {
      // 模拟点击产品节点，显示产品使用榜
      this.currentProductUseTopTitle = `产品 ${product.name} 使用榜`;
      this.currentProductUseTopId = product.id;
      this.productUseTopVisible = true;
      this.$emit('node-click', product); // 向上级组件传递事件
    },
    handleProductUseTopClick(item) {
      // 处理产品使用榜中的文件点击事件
      this.$emit('node-click', item); // 向上级组件传递事件
      this.productUseTopVisible = false; // 关闭弹窗
    }
  }
};
</script>

<style scoped>
.relationship-graph {
  min-height: 400px;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>