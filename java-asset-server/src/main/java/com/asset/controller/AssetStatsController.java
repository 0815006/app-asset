package com.asset.controller;

import com.asset.common.Result;
import com.asset.dto.AssetStatsDTO;
import com.asset.service.AssetStatsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 资产统计接口
 */
@Slf4j
@RestController
@RequestMapping("/api/stats")
@CrossOrigin
public class AssetStatsController {

    @Autowired
    private AssetStatsService assetStatsService;

    /**
     * 获取总览数据
     */
    @GetMapping("/overview")
    public Result<Map<String, Object>> getOverview() {
        Map<String, Object> overview = assetStatsService.getOverview();
        return Result.success(overview);
    }

    /**
     * 获取各产品明细列表
     */
    @GetMapping("/product-details")
    public Result<List<AssetStatsDTO>> getProductDetails() {
        List<AssetStatsDTO> list = assetStatsService.getProductDetails();
        return Result.success(list);
    }
}
