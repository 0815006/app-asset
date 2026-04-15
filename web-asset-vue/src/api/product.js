import request from '@/utils/request'

export function getProductList() {
  return request({
    url: '/products/list',
    method: 'get'
  })
}

export function toggleFavorite(productId, action) {
  return request({
    url: `/products/${productId}/favorite`,
    method: 'post',
    data: { action }
  })
}

export function createProduct(data) {
  return request({
    url: '/products',
    method: 'post',
    data
  })
}

export function updateProduct(id, data) {
  return request({
    url: `/products/${id}`,
    method: 'put',
    data
  })
}

export function initProductFolders(id) {
  return request({
    url: `/products/${id}/init-folders`,
    method: 'post'
  })
}

export function initZoneFolders(type) {
  return request({
    url: '/products/init-zone-folders',
    method: 'post',
    data: { type }
  })
}
