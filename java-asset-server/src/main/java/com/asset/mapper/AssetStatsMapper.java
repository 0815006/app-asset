package com.asset.mapper;

import com.asset.dto.AssetStatsDTO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 资产统计 Mapper
 * 全部采用 SQL 聚合查询，0 张新表
 */
@Mapper
public interface AssetStatsMapper {

    /**
     * 总览：全库文件总数（仅文件，不含文件夹，仅统计归属产品的文件，与明细一致）
     */
    @Select("SELECT COUNT(*) FROM asset_file WHERE node_type = 2 AND is_latest = 1 AND is_deleted = 0 AND product_id > 0")
    Long selectTotalFileCount();

    /**
     * 总览：全库文件总大小 (Bytes，仅统计归属产品的文件，与明细一致)
     */
    @Select("SELECT COALESCE(SUM(file_size), 0) FROM asset_file WHERE node_type = 2 AND is_latest = 1 AND is_deleted = 0 AND product_id > 0")
    Long selectTotalFileSize();

    /**
     * 总览：产品总数
     */
    @Select("SELECT COUNT(*) FROM asset_product WHERE is_deleted = 0")
    Long selectTotalProductCount();

    /**
     * 总览：近30天全库访问量
     */
    @Select("SELECT COUNT(*) FROM asset_access_log WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)")
    Long selectRecent30dAccessCount();

    /**
     * 各产品明细列表
     * JOIN asset_product 获取产品名称，按产品维度聚合 asset_file 和 asset_access_log
     */
    @Select("SELECT " +
            "  p.id AS productId, " +
            "  p.product_name AS productName, " +
            "  p.product_code AS productCode, " +
            "  COALESCE(af.productFileCount, 0) AS productFileCount, " +
            "  COALESCE(af.productFileSize, 0) AS productFileSize, " +
            "  af.lastUpdateTime AS lastUpdateTime, " +
            "  COALESCE(aal.productAccessCount, 0) AS productAccessCount, " +
            "  COALESCE(af.newFileCount30d, 0) AS newFileCount30d, " +
            "  COALESCE(af.contributorCount, 0) AS contributorCount " +
            "FROM asset_product p " +
            "LEFT JOIN ( " +
            "  SELECT " +
            "    product_id, " +
            "    COUNT(*) AS productFileCount, " +
            "    COALESCE(SUM(file_size), 0) AS productFileSize, " +
            "    MAX(updated_at) AS lastUpdateTime, " +
            "    COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) AS newFileCount30d, " +
            "    COUNT(DISTINCT created_by) AS contributorCount " +
            "  FROM asset_file " +
            "  WHERE node_type = 2 AND is_latest = 1 AND is_deleted = 0 " +
            "  GROUP BY product_id " +
            ") af ON p.id = af.product_id " +
            "LEFT JOIN ( " +
            "  SELECT " +
            "    product_id, " +
            "    COUNT(*) AS productAccessCount " +
            "  FROM asset_access_log " +
            "  WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) " +
            "  GROUP BY product_id " +
            ") aal ON p.id = aal.product_id " +
            "WHERE p.is_deleted = 0 " +
            "ORDER BY af.productFileCount DESC")
    List<AssetStatsDTO> selectProductDetails();
}
