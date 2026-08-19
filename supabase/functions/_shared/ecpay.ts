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
  const keys = Object.keys(params)
    .filter((key) => key !== 'CheckMacValue' && params[key] !== undefined && params[key] !== '')
    .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))

  let raw = `HashKey=${hashKey}`
  for (const key of keys) {
    raw += `&${key}=${params[key]}`
  }
  raw += `&HashIV=${hashIV}`

  const encoded = ecpayUrlEncode(raw).toLowerCase()
  return await sha256Upper(encoded)
}
