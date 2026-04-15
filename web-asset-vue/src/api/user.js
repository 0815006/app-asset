import request from '@/utils/request'

export function login(data) {
  return request({
    url: '/login', // Removed /api
    method: 'post',
    data
  })
}

export function getInfo(token) {
  return Promise.resolve({
    data: {
      name: '陈东',
      avatar: ''
    }
  })
}

export function logout() {
  return Promise.resolve()
}

export function getUserList() {
  return request({
    url: '/users/list', // Removed /api
    method: 'get'
  })
}

export function changePassword(data) {
  return request({
    url: '/user/change-password', // Removed /api
    method: 'post',
    data
  })
}
