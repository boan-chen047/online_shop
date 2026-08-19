import { supabase } from '@/lib/supabase'

interface EcpayCreateResult {
  ecpayUrl: string
  params: Record<string, string>
}

// 呼叫 ecpay-create Edge Function 取得綠界參數，然後動態組表單 POST 導向綠界收銀台。
// 送出後瀏覽器會離開本頁前往綠界，因此這個函式正常情況不會 resolve。
export async function startEcpayPayment(orderId: string) {
  const { data, error } = await supabase.functions.invoke<EcpayCreateResult>('ecpay-create', {
    body: { orderId, backOrigin: window.location.origin },
  })

  if (error) {
    // functions.invoke 只給籠統訊息，真正的錯誤在 error.context（Response）裡，撈出來顯示
    let detail = ''
    const context = (error as { context?: Response }).context
    if (context && typeof context.json === 'function') {
      try {
        const body = await context.clone().json()
        detail = (body as { error?: string })?.error ?? ''
      } catch {
        try {
          detail = await context.clone().text()
        } catch {
          detail = ''
        }
      }
    }
    throw new Error(detail ? `付款建立失敗：${detail}` : (error.message || '付款建立失敗，請稍後再試。'))
  }
  if (!data?.ecpayUrl || !data?.params) {
    throw new Error('付款資料建立失敗，請稍後再試。')
  }

  const form = document.createElement('form')
  form.method = 'POST'
  form.action = data.ecpayUrl
  form.style.display = 'none'
  form.acceptCharset = 'UTF-8'

  for (const [name, value] of Object.entries(data.params)) {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = name
    input.value = value
    form.appendChild(input)
  }

  document.body.appendChild(form)
  form.submit()
}
