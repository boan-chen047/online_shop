// ecpay-create：接收 orderId，驗證使用者擁有該訂單，於伺服器端用 HashKey/HashIV
// 產生綠界所需參數與 CheckMacValue，回傳給前端組表單導向綠界收銀台。
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { makeCheckMacValue } from '../_shared/ecpay.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { orderId, backOrigin } = await req.json().catch(() => ({}))
    if (!orderId) return json({ error: '缺少 orderId' }, 400)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    // 用呼叫者的 JWT 確認身分（明確取出 token 再驗證，較穩健）
    const authHeader = req.headers.get('Authorization') ?? ''
    const token = authHeader.replace(/^Bearer\s+/i, '')
    if (!token) return json({ error: '缺少授權（未登入）' }, 401)

    // 帶上使用者的 token 建立 client，之後查詢會以其身分套用 RLS
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    })
    const { data: userData, error: userError } = await userClient.auth.getUser(token)
    if (userError || !userData.user) {
      return json({ error: `未登入或授權失效${userError ? '：' + userError.message : ''}` }, 401)
    }

    // 以使用者自己的權限讀訂單（RLS: orders_select_own），只讀得到自己的訂單
    const { data: order, error: orderError } = await userClient
      .from('orders')
      .select('id, user_id, total, payment_status, order_items(product_name, quantity)')
      .eq('id', orderId)
      .maybeSingle()

    if (orderError || !order) {
      const dbg = `orderId=${orderId}, err=${orderError ? `${(orderError as { code?: string }).code ?? ''}:${orderError.message}` : 'no-row'}`
      return json({ error: `找不到訂單 (${dbg})` }, 404)
    }
    if (order.user_id !== userData.user.id) return json({ error: '無權限' }, 403)
    if (order.payment_status === 'paid') return json({ error: '訂單已付款' }, 400)

    const merchantId = Deno.env.get('ECPAY_MERCHANT_ID')!
    const hashKey = Deno.env.get('ECPAY_HASH_KEY')!
    const hashIV = Deno.env.get('ECPAY_HASH_IV')!
    const ecpayUrl = Deno.env.get('ECPAY_API_URL') ??
      'https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5'

    const now = new Date()
    const pad = (n: number) => String(n).padStart(2, '0')
    const tradeDate =
      `${now.getFullYear()}/${pad(now.getMonth() + 1)}/${pad(now.getDate())} ` +
      `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`

    // MerchantTradeNo 需唯一、≤20 碼、英數字
    const merchantTradeNo = `EC${Date.now()}${Math.floor(Math.random() * 900 + 100)}`.slice(0, 20)

    const items = (order.order_items ?? []) as Array<{ product_name: string; quantity: number }>
    const itemName = (items.length
      ? items.map((item) => `${item.product_name} x${item.quantity}`).join('#')
      : '線上購物商品'
    ).replace(/[&+]/g, ' ').slice(0, 400)

    const params: Record<string, string> = {
      MerchantID: merchantId,
      MerchantTradeNo: merchantTradeNo,
      MerchantTradeDate: tradeDate,
      PaymentType: 'aio',
      TotalAmount: String(Math.round(Number(order.total))),
      TradeDesc: 'Online Shop Order',
      ItemName: itemName,
      ReturnURL: `${supabaseUrl}/functions/v1/ecpay-callback`,
      ChoosePayment: 'ALL',
      EncryptType: '1',
      CustomField1: String(order.id),
      // 讓綠界端的繳費期限對齊系統的三天逾時：
      // 信用卡為即時付款、沒有殘留待付款；ATM 虛擬帳號以 ExpireDate（天）控制繳費期限。
      // 超商代碼繳費的 StoreExpireDate 單位與上限依付款方式而異，待接超商時再對照綠界文件補上。
      ExpireDate: '3',
    }

    if (typeof backOrigin === 'string' && backOrigin.startsWith('http')) {
      // ClientBackURL：綠界成功頁「返回商店」按鈕（手動備援）
      params.ClientBackURL = `${backOrigin}/checkout/result?order=${order.id}`
      // OrderResultURL：綠界付款後自動 POST 到此，由 ecpay-result 轉回前端結果頁（免手動點）
      params.OrderResultURL =
        `${supabaseUrl}/functions/v1/ecpay-result?back=${encodeURIComponent(backOrigin)}&order=${order.id}`
    }

    params.CheckMacValue = await makeCheckMacValue(params, hashKey, hashIV)

    return json({ ecpayUrl, params })
  } catch (error) {
    return json({ error: String(error) }, 500)
  }
})
