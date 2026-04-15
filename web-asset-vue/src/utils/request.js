import axios from 'axios'
import { Message } from 'element-ui'

// 创建 axios 实例
const service = axios.create({
  baseURL: '/api', // url = base url + request url
  timeout: 30000 // request timeout increased to 30s
})

// request interceptor
service.interceptors.request.use(
  config => {
    // do something before request is sent
    const token = localStorage.getItem('token')
    const userId = localStorage.getItem('userId')
    if (token) {
       config.headers['Authorization'] = 'Bearer ' + token
    }
    if (userId) {
       config.headers['X-User-Id'] = userId
    }
    return config
  },
  error => {
    // do something with request error
    console.log(error) // for debug
    return Promise.reject(error)
  }
)

// response interceptor
service.interceptors.response.use(
  /**
   * If you want to get http information such as headers or status
   * Please return  response => response
  */

  /**
   * Determine the request status by custom code
   * Here is just an example
   * You can also judge the status by HTTP Status Code
   */
  response => {
    // 如果是 HEAD 请求，直接返回响应（HEAD 请求没有响应体）
    if (response.config.method === 'head') {
      return response
    }

    // 如果是 Blob、ArrayBuffer 或 Text 类型，直接返回
    if (['blob', 'arraybuffer', 'text'].includes(response.config.responseType)) {
      return response.data
    }

    const res = response.data

    // if the custom code is not 200, it is judged as an error.
    if (res.code !== 200) {
      if (!response.config.silent) {
        Message({
          message: res.message || 'Error',
          type: 'error',
          duration: 5 * 1000
        })
      }
      return Promise.reject(new Error(res.message || 'Error'))
    } else {
      return res.data
    }
  },
  error => {
    console.log('err' + error) // for debug
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('userId')
      localStorage.removeItem('userInfo')
      window.location.href = '/login'
    }
    if (!error.config || !error.config.silent) {
      Message({
        message: error.message,
        type: 'error',
        duration: 5 * 1000
      })
    }
    return Promise.reject(error)
  }
)

export default service
