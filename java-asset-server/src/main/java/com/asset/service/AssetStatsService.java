package com.asset.service;

import com.asset.dto.AssetStatsDTO;
import com.asset.mapper.AssetStatsMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产统计服务
 */
@Slf4j
@Service
public class AssetStatsService {

    @Autowired
    private AssetStatsMapper assetStatsMapper;

    /**
     * 获取总览数据
     */
    public Map<String, Object> getOverview() {
        Map<String, Object> overview = new HashMap<>();
        overview.put("totalFileCount", assetStatsMapper.selectTotalFileCount());
        overview.put("totalFileSize", assetStatsMapper.selectTotalFileSize());
        overview.put("totalFileSizeFormatted", AssetStatsDTO.formatFileSize(assetStatsMapper.selectTotalFileSize()));
        overview.put("totalProductCount", assetStatsMapper.selectTotalProductCount());
        overview.put("recent30dAccessCount", assetStatsMapper.selectRecent30dAccessCount());
        return overview;
    }

    /**
     * 获取各产品明细列表
     * 自动格式化 fileSize
     */
    public List<AssetStatsDTO> getProductDetails() {
        List<AssetStatsDTO> list = assetStatsMapper.selectProductDetails();
        // 后处理：补充格式化字段
        for (AssetStatsDTO dto : list) {
            if (dto.getProductFileSize() != null) {
                // 可以直接用 DTO 里的静态方法在前端做，也可以在后端做
                // 这里保持原始数据，前端格式化
            }
        }
        return list;
    }
}
