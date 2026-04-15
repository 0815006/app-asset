<template>
  <el-dialog
    title="产品维护"
    :visible.sync="visible"
    width="600px"
    :before-close="handleClose"
    append-to-body
    class="product-mgmt-dialog">
    
    <div class="dialog-content">
      <div class="header-actions">
        <el-button type="primary" size="small" icon="el-icon-plus" @click="showCreateDialog">创建新产品</el-button>
      </div>

      <div class="product-selector">
        <span class="selector-label">选择需要维护的产品：</span>
        <el-select v-model="selectedProductId" placeholder="请选择要维护的产品" style="flex: 1;" filterable @change="handleProductSelect">
          <el-option
            v-for="item in products"
            :key="item.id"
            :label="item.productCode ? `${item.productName} (${item.productCode})` : item.productName"
            :value="item.id">
          </el-option>
        </el-select>
      </div>

      <div v-if="selectedProduct" class="product-info-list">
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="产品名称">{{ selectedProduct.productName }}</el-descriptions-item>
          <el-descriptions-item label="英文简称">{{ selectedProduct.productCode || '-' }}</el-descriptions-item>
          <el-descriptions-item label="所属团队">{{ selectedProduct.teamName }}</el-descriptions-item>
          <el-descriptions-item label="业务领域">{{ selectedProduct.domainName }}</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ selectedProduct.ownerName }}</el-descriptions-item>
          <el-descriptions-item label="资产数">{{ selectedProduct.assetCount }}</el-descriptions-item>
        </el-descriptions>
      </div>

      <div v-if="selectedProduct" class="product-actions">
        <el-button size="medium" type="primary" plain icon="el-icon-edit" @click="showEditDialog(selectedProduct)">编辑产品信息</el-button>
      </div>
    </div>

    <!-- 创建/编辑产品弹窗 -->
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="500px" append-to-body>
      <el-form :model="productForm" :rules="productRules" ref="productForm" label-width="100px">
        <el-form-item label="产品名称" prop="productName">
          <el-input v-model="productForm.productName" placeholder="请输入产品名称"></el-input>
        </el-form-item>
        <el-form-item label="英文简称" prop="productCode">
          <el-input v-model="productForm.productCode" placeholder="请输入产品英文简称"></el-input>
        </el-form-item>
        <el-form-item label="所属团队" prop="teamName">
          <el-input v-model="productForm.teamName" placeholder="请输入所属团队"></el-input>
        </el-form-item>
        <el-form-item label="业务领域" prop="domainName">
          <el-input v-model="productForm.domainName" placeholder="请输入业务领域"></el-input>
        </el-form-item>
        <el-form-item label="负责人" prop="ownerIds">
          <el-select v-model="productForm.ownerIds" placeholder="请选择负责人" style="width: 100%;" filterable multiple :multiple-limit="10">
            <el-option
              v-for="user in userList"
              :key="user.id"
              :label="user.realName"
              :value="user.id">
            </el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="submitProductForm" :loading="dialogLoading">确 定</el-button>
      </div>
    </el-dialog>
  </el-dialog>
</template>

<script>
import { getProductList, createProduct, updateProduct } from "@/api/product";
import { getUserList } from "@/api/user";

export default {
  name: "ProductMgmtDialog",
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      loading: false,
      products: [],
      userList: [],
      selectedProductId: null,
      dialogVisible: false,
      dialogTitle: "",
      isEdit: false,
      productForm: {
        id: null,
        productName: "",
        productCode: "",
        teamName: "",
        domainName: "",
        ownerIds: [],
      },
      productRules: {
        productName: [{ required: true, message: "请输入产品名称", trigger: "blur" }],
        productCode: [{ required: true, message: "请输入产品英文简称", trigger: "blur" }],
        teamName: [{ required: true, message: "请输入所属团队", trigger: "blur" }],
        domainName: [{ required: true, message: "请输入业务领域", trigger: "blur" }],
        ownerIds: [{ type: 'array', required: true, message: "请选择负责人", trigger: "change" }],
      },
      dialogLoading: false,
    };
  },
  computed: {
    selectedProduct() {
      if (!this.selectedProductId) return null;
      return this.products.find(p => p.id === this.selectedProductId);
    }
  },
  watch: {
    visible(val) {
      if (val) {
        this.fetchProducts();
        this.fetchUserList();
        this.selectedProductId = null; // 每次打开重置选择
      }
    }
  },
  methods: {
    handleClose() {
      this.$emit('update:visible', false);
    },
    async fetchProducts() {
      this.loading = true;
      try {
        const res = await getProductList();
        this.products = (res || []).map(p => ({ ...p, initLoading: false }));
      } catch (error) {
        console.error("Failed to fetch products:", error);
        this.$message.error("获取产品列表失败");
      } finally {
        this.loading = false;
      }
    },
    async fetchUserList() {
      try {
        const res = await getUserList(); 
        this.userList = res || [];
      } catch (error) {
        console.error("Failed to fetch user list:", error);
      }
    },
    handleProductSelect(val) {
      // 选择产品时的处理，目前通过 computed 属性 selectedProduct 自动处理
    },
    showCreateDialog() {
      this.dialogVisible = true;
      this.dialogTitle = "创建新产品";
      this.isEdit = false;
      this.productForm = {
        id: null,
        productName: "",
        productCode: "",
        teamName: "",
        domainName: "",
        ownerIds: [],
      };
      this.$nextTick(() => {
        this.$refs.productForm.clearValidate();
      });
    },
    showEditDialog(row) {
      this.dialogVisible = true;
      this.dialogTitle = "编辑产品";
      this.isEdit = true;
      // 将逗号分隔的字符串转为数组
      const ownerIds = row.ownerIds ? String(row.ownerIds).split(',').map(id => id.trim()).filter(id => id).map(id => isNaN(id) ? id : Number(id)) : [];
      this.productForm = { ...row, ownerIds };
      this.$nextTick(() => {
        this.$refs.productForm.clearValidate();
      });
    },
    async submitProductForm() {
      this.$refs.productForm.validate(async (valid) => {
        if (valid) {
          this.dialogLoading = true;
          try {
            // 将数组转为逗号分隔的字符串提交
            const submitData = {
              ...this.productForm,
              ownerIds: this.productForm.ownerIds.join(',')
            };
            
            if (this.isEdit) {
              await updateProduct(submitData.id, submitData);
              this.$message.success("产品信息更新成功");
            } else {
              const res = await createProduct(submitData);
              this.$message.success("新产品创建成功");
              // 如果是新建，自动选中新建的产品
              if (res && res.id) {
                this.selectedProductId = res.id;
              }
            }
            this.dialogVisible = false;
            await this.fetchProducts();
            this.$emit('refresh-data'); // 通知父组件刷新数据
          } catch (error) {
            console.error("Failed to save product:", error);
            this.$message.error("保存产品信息失败");
          } finally {
            this.dialogLoading = false;
          }
        }
      });
    },
  },
};
</script>

<style scoped>
.product-mgmt-dialog /deep/ .el-dialog__body {
  padding-top: 10px;
  padding-bottom: 30px;
}

.dialog-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.header-actions {
  display: flex;
  justify-content: flex-end;
}

.product-selector {
  margin-top: 10px;
  display: flex;
  align-items: center;
}

.selector-label {
  font-size: 14px;
  color: #606266;
  margin-right: 10px;
  white-space: nowrap;
}

.product-info-list {
  margin-top: 10px;
}

.product-actions {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px dashed #ebeef5;
}
</style>
