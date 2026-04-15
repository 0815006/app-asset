import request from '@/utils/request'

export function search(params) {
  return request({
    url: '/search',
    method: 'get',
    params
  })
}

export function getSearchHealthCheck() {
  return request({
    url: '/search/health-check',
    method: 'get'
  })
}

export function reindexAsset(id) {
  return request({
    url: `/search/reindex/${id}`,
    method: 'post'
  })
}

export function deleteSearchIndex(solrId) {
  return request({
    url: `/search/index/${solrId}`,
    method: 'delete'
  })
}

export function startRebuildAll() {
  return request({
    url: '/search/rebuild-all/start',
    method: 'post'
  })
}

export function getRebuildProgress() {
  return request({
    url: '/search/rebuild-all/progress',
    method: 'get'
  })
}

// 新增 API
export function getHotKeywords(params) {
  return request({
    url: '/search/hot-keywords',
    method: 'get',
    params
  })
}

export function getGlobalUseTop(params) {
  return request({
    url: '/search/global-use-top',
    method: 'get',
    params
  })
}

export function getGlobalStarTop(params) {
  return request({
    url: '/search/global-star-top',
    method: 'get',
    params
  })
}
