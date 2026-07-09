package com.asset.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 资产统计数据传输对象
 */
@Data
public class AssetStatsDTO {

    // ========== 总览字段 ==========
    /** 全库文件总数（仅文件，不含文件夹） */
    private Long totalFileCount;

    /** 全库文件总大小 (Bytes) */
    private Long totalFileSize;

    /** 产品总数 */
    private Long totalProductCount;

    /** 近30天全库访问量 */
    private Long recent30dAccessCount;

    // ========== 各产品明细字段 ==========
    /** 产品ID */
    private Long productId;

    /** 产品名称 */
    private String productName;

    /** 产品英文简称（编码） */
    private String productCode;

    /** 该产品文件总数 */
    private Long productFileCount;

    /** 该产品文件总大小 (Bytes) */
    private Long productFileSize;

    /** 该产品最近更新日期 */
    private LocalDateTime lastUpdateTime;

    /** 该产品近30天访问量 */
    private Long productAccessCount;

    /** 该产品近30天新增文件数 */
    private Long newFileCount30d;

    /** 该产品参与维护人数 */
    private Long contributorCount;

    /**
     * 格式化文件大小（Bytes → 可读字符串）
     */
    public static String formatFileSize(Long bytes) {
        if (bytes == null || bytes == 0) return "0 B";
        String[] units = {"B", "KB", "MB", "GB", "TB"};
        int unitIndex = 0;
        double size = bytes.doubleValue();
        while (size >= 1024 && unitIndex < units.length - 1) {
            size /= 1024;
            unitIndex++;
        }
        if (size >= 100) {
            return String.format("%.0f %s", size, units[unitIndex]);
        } else if (size >= 10) {
            return String.format("%.1f %s", size, units[unitIndex]);
        } else {
            return String.format("%.2f %s", size, units[unitIndex]);
        }
    }
}
