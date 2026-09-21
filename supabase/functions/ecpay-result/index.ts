// ecpay-result：綠界 OrderResultURL 的目標。
//
// 綠界付款完成後會由「瀏覽器 client-side POST」把付款結果送到 OrderResultURL。
// 前端 SPA 無法接收 POST（靜態主機對 POST 會回 405），所以用這支 Edge Function 當橋接：
// 收到綠界的 POST 後，以 303 轉址（POST → GET）把瀏覽器導回前端的付款結果頁，
// SPA 就能正常以 GET 載入。真正的付款狀態更新由 ecpay-callback（ReturnURL）負責，與此無關。
// 這支不帶使用者 JWT，config.toml 需設 verify_jwt = false。
Deno.serve((req) => {
  const url = new URL(req.url)
  const back = url.searchParams.get('back') ?? ''
  const order = url.searchParams.get('order') ?? ''

  // 只接受 http(s) 開頭的站內來源，避免被導向外部網址（open redirect）
  const safeBack = back.startsWith('http') ? back : ''
  const dest = safeBack
    ? `${safeBack}/checkout/result?order=${encodeURIComponent(order)}`
    : '/'

  return new Response(null, {
    status: 303,
    headers: { Location: dest },
  })
})
