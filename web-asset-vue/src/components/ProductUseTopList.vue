<template>
  <div class="product-use-top-list">
    <el-table :data="topList" style="width: 100%" stripe>
      <el-table-column type="index" label="排名" width="80"></el-table-column>
      <el-table-column label="文件名称" prop="fileName">
        <template slot-scope="scope">
          <asset-item :asset="scope.row" @node-click="handleItemClick"></asset-item>
        </template>
      </el-table-column>
      <el-table-column label="访问次数" prop="use_count" width="100"></el-table-column>
    </el-table>
  </div>
</template>

<script>
import { getProductUseTop } from "@/api/asset-node"; // 假设 asset-node.js 中有此 API
import AssetItem from "./AssetItem.vue"; // 导入 AssetItem 组件

export default {
  name: "ProductUseTopList",
  components: {
    AssetItem,
  },
  props: {
    productId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      topList: [],
    };
  },
  watch: {
    productId: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.fetchProductUseTop(newVal);
        } else {
          this.topList = [];
        }
      },
    },
  },
  methods: {
    async fetchProductUseTop(productId) {
      try {
        const res = await getProductUseTop(productId, { limit: 10 }); // 获取产品使用榜的前10个文件
        // res 中的每个对象包含 file_id 和 use_count
        // 我们需要根据 file_id 获取 AssetFile 的详细信息
        // 暂时模拟数据，或者等待后端 API
        this.topList = (res || []).map((item) => ({
          id: item.file_id,
          fileName: `文件 ${item.file_id}`, // 临时文件名
          use_count: item.use_count,
          isNew: false, // 榜单不显示 New 状态
        }));
      } catch (error) {
        console.error("Failed to fetch product use top list:", error);
        this.$message.error("获取产品使用榜失败");
      }
    },
    handleItemClick(item) {
      this.$emit("node-click", item);
    },
  },
};
</script>

<style scoped>
.product-use-top-list {
  /* 样式 */
}
</style>