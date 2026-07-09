import request from '@/utils/request'

/**
 * 资产统计 API
 */
export function getOverview() {
  return request({
    url: '/stats/overview',
    method: 'get'
  })
}

export function getProductDetails() {
  return request({
    url: '/stats/product-details',
    method: 'get'
  })
}
