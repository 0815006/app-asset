import request from '@/utils/request'

export function getAssetTree(params) {
  return request({
    url: '/assets/tree',
    method: 'get',
    params
  })
}

export function createFolder(data) {
  return request({
    url: '/assets/folder',
    method: 'post',
    data
  })
}

export function renameAsset(id, newName) {
  return request({
    url: `/assets/${id}/rename`,
    method: 'put',
    data: { new_name: newName }
  })
}

export function moveAsset(id, targetParentId) {
  return request({
    url: `/assets/${id}/move`,
    method: 'put',
    data: { target_parent_id: targetParentId }
  })
}

export function deleteAsset(id) {
  return request({
    url: `/assets/${id}`,
    method: 'delete'
  })
}

export function acquireLock(id) {
  return request({
    url: `/assets/${id}/lock`,
    method: 'post'
  })
}

export function keepAliveLock(id, lockId) {
  return request({
    url: `/assets/${id}/lock/keepalive`,
    method: 'put',
    data: { lock_id: lockId }
  })
}

export function unlockAsset(id, lockId) {
  return request({
    url: `/assets/${id}/unlock`,
    method: 'post',
    data: { lock_id: lockId }
  })
}

export function uploadFile(data) {
  return request({
    url: '/assets/upload',
    method: 'post',
    data,
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

export function updateAsset(id, data) {
  return request({
    url: `/assets/${id}/update`,
    method: 'post',
    data,
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

export function downloadAssets(data) {
  return request({
    url: '/assets/download',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

export function getAssetDetails(id, params) {
  return request({
    url: `/assets/${id}/details`,
    method: 'get',
    params
  })
}

export function getBatchDetails(data) {
  return request({
    url: '/assets/batch-details',
    method: 'post',
    data
  })
}

// 新增 API
export function recordReadState(data) {
  return request({
    url: '/assets/record-read-state',
    method: 'post',
    data
  })
}

export function getMyStarredFiles(params) {
  return request({
    url: '/assets/my-stars',
    method: 'get',
    params
  })
}

export function starFile(fileId, params) {
  return request({
    url: `/assets/star/${fileId}`,
    method: 'post',
    params
  })
}

export function unstarFile(fileId, params) {
  return request({
    url: `/assets/star/${fileId}`,
    method: 'delete',
    params
  })
}

export function pinFile(fileId, params) {
  return request({
    url: `/assets/star/${fileId}/pin`,
    method: 'post',
    params
  })
}

export function getLatestUpdates(params) {
  return request({
    url: '/assets/latest-updates',
    method: 'get',
    params
  })
}

export function getCuratedAssets(productId) {
  return request({
    url: `/assets/curated/${productId}`,
    method: 'get'
  })
}

export function getProductUseTop(productId, params) {
  return request({
    url: `/assets/product-use-top/${productId}`,
    method: 'get',
    params
  })
}

export function getRecentAccessedFiles(params) {
  return request({
    url: '/assets/recent-access',
    method: 'get',
    params
  })
}

export function getProductCuratedAssets(productId) {
  return request({
    url: `/assets/product/${productId}/curated-assets`,
    method: 'get'
  })
}

export function getProductUseRanking(productId) {
  return request({
    url: `/assets/product/${productId}/use-ranking`,
    method: 'get'
  })
}

export function toggleCuratedStatus(data) {
  return request({
    url: '/assets/curated',
    method: 'post',
    data
  })
}

export function getCuratedStatus(params) {
  return request({
    url: '/assets/curated/status',
    method: 'get',
    params
  })
}

export function getRecycleBin() {
  return request({
    url: '/assets/recycle-bin',
    method: 'get'
  })
}

export function restoreAsset(id) {
  return request({
    url: `/assets/${id}/restore`,
    method: 'post'
  })
}

export function permanentDeleteAsset(id) {
  return request({
    url: `/assets/${id}/permanent`,
    method: 'delete'
  })
}

export function restoreAllAssets() {
  return request({
    url: '/assets/restore-all',
    method: 'post'
  })
}

export function permanentDeleteAllAssets() {
  return request({
    url: '/assets/permanent-all',
    method: 'delete'
  })
}

export function getBatchProgress(taskId) {
  return request({
    url: `/assets/batch-progress/${taskId}`,
    method: 'get'
  })
}

export function getStoragePath(params) {
  return request({
    url: '/assets/storage-path',
    method: 'get',
    params
  })
}

export function createRootDir(data) {
  return request({
    url: '/assets/create-root-dir',
    method: 'post',
    data
  })
}

export function healthCheck(params) {
  return request({
    url: '/assets/health-check',
    method: 'get',
    params
  })
}

export function syncExtra(data) {
  return request({
    url: '/assets/sync-extra',
    method: 'post',
    data
  })
}

export function getSyncProgress(params) {
  return request({
    url: '/assets/sync-progress',
    method: 'get',
    params
  })
}

export function checkAssetExistence(id, params) {
  return request({
    url: `/assets/${id}/view`,
    method: 'head',
    params,
    silent: true
  })
}

export function getAssetPreviewData(id, params, onDownloadProgress) {
  return request({
    url: `/assets/${id}/view`,
    method: 'get',
    params,
    responseType: 'arraybuffer',
    onDownloadProgress
  })
}

export function getAssetTextContent(id, params) {
  return request({
    url: `/assets/${id}/view`,
    method: 'get',
    params,
    responseType: 'text'
  })
}
