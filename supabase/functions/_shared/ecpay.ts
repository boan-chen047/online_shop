// 綠界 CheckMacValue 產生 / 驗證工具（Deno / Edge Function 用）。
// 演算法依綠界規格：參數排序 → 前後接 HashKey/HashIV → .NET 風格 URL encode
// → 轉小寫 → SHA256 → 轉大寫。

function ecpayUrlEncode(input: string): string {
  return encodeURIComponent(input)
    .replace(/%20/g, '+')
    .replace(/%21/g, '!')
    .replace(/%2A/g, '*')
    .replace(/%28/g, '(')
    .replace(/%29/g, ')')
    .replace(/%2D/g, '-')
    .replace(/%2E/g, '.')
    .replace(/%5F/g, '_')
}

async function sha256Upper(input: string): Promise<string> {
  const data = new TextEncoder().encode(input)
  const buf = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase()
}

export async function makeCheckMacValue(
  params: Record<string, string>,
  hashKey: string,
  hashIV: string,
): Promise<string> {
  // 只排除 CheckMacValue 本身與未設定(undefined)的參數。
  // 注意：不可濾掉空字串值——綠界的付款結果通知會回傳 CustomField2=、CustomField3=、
  // StoreID= 等空值欄位，且綠界計算 CheckMacValue 時「有把空值欄位算進去」；
  // 若這裡把空值濾掉，回傳通知的驗章就會永遠對不上，導致付款成功卻無法標記訂單。
  const keys = Object.keys(params)
    .filter((key) => key !== 'CheckMacValue' && params[key] !== undefined)
    .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))

  let raw = `HashKey=${hashKey}`
  for (const key of keys) {
    raw += `&${key}=${params[key]}`
  }
  raw += `&HashIV=${hashIV}`

  const encoded = ecpayUrlEncode(raw).toLowerCase()
  return await sha256Upper(encoded)
}
