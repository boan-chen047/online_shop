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
      // 交由 mark_order_paid 於單一交易內：確認幂等、把預留庫存結清成實際售出，
      // 並處理「逾時取消後才收到的遲到付款」（有貨復活、沒貨標記缺貨待退款）。
      const { data: result, error: rpcError } = await admin.rpc('mark_order_paid', {
        p_order_id: params.CustomField1,
      })

      if (rpcError) {
        // 結清失敗（例如短暫的資料庫錯誤）：回非 1 讓綠界稍後重送，交易紀錄不遺失。
        return new Response(`0|${rpcError.message}`, { status: 200 })
      }

      // result 為 'paid_out_of_stock' 時代表已收款但缺貨，需後續退款；此處仍回 1|OK，
      // 避免綠界重送，缺貨退款由訂單狀態 out_of_stock 走人工／後續自動流程處理。
      void result
    }

    // 一定要回覆 1|OK，否則綠界會持續重送通知
    return new Response('1|OK', { status: 200 })
  } catch (error) {
    return new Response(`0|${String(error)}`, { status: 200 })
  }
})
