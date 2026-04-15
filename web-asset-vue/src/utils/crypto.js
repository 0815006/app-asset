import CryptoJS from 'crypto-js'

// 约定好的 Key 和 IV (必须与后端一致，16位)
const keyStr = 'ihaierForTodoKey'
const ivStr = 'ihaierForTodo_Iv'

/**
 * AES 加密 (CBC模式)
 * @param {String} text 明文
 * @returns {String} Base64 密文
 */
export function aesEncrypt(text) {
  if (!text) return ''
  const key = CryptoJS.enc.Utf8.parse(keyStr)
  const iv = CryptoJS.enc.Utf8.parse(ivStr)
  const encrypted = CryptoJS.AES.encrypt(text, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7
  })
  return encrypted.toString()
}

/**
 * MD5 哈希
 * @param {String} text 明文
 * @returns {String} MD5 密文
 */
export function md5Encrypt(text) {
  if (!text) return ''
  return CryptoJS.MD5(text).toString()
}
