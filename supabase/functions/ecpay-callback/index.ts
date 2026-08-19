// ecpay-callback：綠界付款結果的 server-to-server 通知（ReturnURL）。
// 驗證 CheckMacValue，付款成功則把訂單 payment_status 改成 paid，並回覆 "1|OK"。
// 這支函式沒有使用者 JWT，config.toml 需設 verify_jwt = false。
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { makeCheckMacValue } from '../_shared/ecpay.ts'

Deno.serve(async (req) => {
  try {
    // 綠界以 application/x-www-form-urlencoded POST
    const rawText = await req.text()
    const params: Record<string, string> = {}
    new URLSearchParams(rawText).forEach((value, key) => {
      params[key] = value
    })

    const hashKey = Deno.env.get('ECPAY_HASH_KEY')!
    const hashIV = Deno.env.get('ECPAY_HASH_IV')!

    const received = (params.CheckMacValue ?? '').toUpperCase()
    const computed = await makeCheckMacValue(params, hashKey, hashIV)

    if (!received || received !== computed) {
      return new Response('0|CheckMacValue error', { status: 200 })
    }

    // RtnCode = 1 代表付款成功
    if (params.RtnCode === '1' && params.CustomField1) {
      const admin = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      )
      await admin
        .from('orders')
        .update({ payment_status: 'paid', paid_at: new Date().toISOString() })
        .eq('id', params.CustomField1)
        .eq('payment_status', 'unpaid')
    }

    // 一定要回覆 1|OK，否則綠界會持續重送通知
    return new Response('1|OK', { status: 200 })
  } catch (error) {
    return new Response(`0|${String(error)}`, { status: 200 })
  }
})
