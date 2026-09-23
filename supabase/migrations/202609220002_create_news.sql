-- 最新消息（新聞）表；取代前端寫死的 src/data/news.ts
create table if not exists public.news (
  id bigint generated always as identity primary key,
  tag text not null default '',
  title text not null default '',
  description text not null default '',
  image_url text not null default '',
  alt text not null default '',
  read_time text not null default '',
  published_at date not null default current_date,
  intro text not null default '',
  section_title text not null default '',
  section_body_1 text not null default '',
  quote_text text not null default '',
  quote_author text not null default '',
  section_body_2 text not null default '',
  created_at timestamptz not null default now()
);

-- 列表預設依發布日新到舊
create index if not exists news_published_at_idx on public.news (published_at desc, id desc);

alter table public.news enable row level security;

-- 公開可讀（比照 catalog / site_settings 的 public read）
grant select on public.news to anon, authenticated;
-- 寫入交給 RLS 把關，僅開放 authenticated 嘗試
grant insert, update, delete on public.news to authenticated;

drop policy if exists "news_public_read" on public.news;
create policy "news_public_read"
on public.news
for select
to anon, authenticated
using (true);

-- 僅管理員可寫（用整併後的 public.is_admin()）
drop policy if exists "news_admin_manage" on public.news;
create policy "news_admin_manage"
on public.news
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- 種子資料：4 篇中文範例公告（僅在表為空時寫入，避免重複灌）
insert into public.news
  (tag, title, description, image_url, alt, read_time, published_at,
   intro, section_title, section_body_1, quote_text, quote_author, section_body_2)
select * from (values
  (
    '新品上架',
    '本月嚴選新品上架，在地好味道一次到齊',
    '精選來自全台各地的人氣好物，從在地零食到季節限定，全新品項正式開賣。',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCGjQCP61VxUmioEYuzMy_f7I9md4BcSeMlOMbQL6G3y1VIUZV0rb0to-g_AK1fpiyfJM2fAQ1XTCOP85PLX00pE4xdPfYOcT1yUicngaBiRwCJOMOCGTdOSV5NnZ147f7w0f3aUmG5b_6KJEiFDEQBJl0pe8cn29AL0XYi-KDMcr0VTfpNyKTBOcRmw7QGQq3X0FaWys_jUG75QmlU59skO39G1NImwC9uMpcBPvosEt_vCv2_j_toynCy15ZdCbdtfiTK-_GGtkM',
    '新品上架',
    '3 分鐘閱讀',
    date '2024-10-24',
    '這個月我們走訪各地小農與職人，帶回一批全新商品，希望讓你在家也能吃到最道地的好味道。',
    '嚴選在地，產地直送',
    '所有新品皆經過團隊親自試吃把關，並與產地合作採用最新鮮的原料，從下單到出貨都力求維持最佳品質。',
    '「我們想做的，是把產地的用心，原封不動地送到你手上。」',
    '採購團隊',
    '新品數量有限，售完為止，喜歡的話別猶豫，快到商品頁看看有沒有你的口袋名單。'
  ),
  (
    '限時活動',
    '限時折扣活動預告，鎖定首頁倒數搶好康',
    '精選商品限時特價，活動期間首頁將顯示即時折扣價，錯過就要等下次。',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDM_uBSVfiqkC9r6dVKtKhk6ipS_KIJ1Ngk-ukj6OZ9rMiIC2o-dNRVf619W7MiobJLoUEl2zdFcDEdYawmKnKkdJ1HkXUY1XrPWX4LPu1X7WUVWX9m2pf0LbWY4bYIQVjMAWGExc0g01PmJF2W1Rp7ohlq4In7hO3mS7XMRsAtKGC5kQC6XTten353y-OlLB52phCEvux3wTwhEETSI2mJ0laepi1QVRgTVsLXyW81vbiEgulUtfoVi9d10ydDu-vszp_Svh5fTx4',
    '限時活動',
    '2 分鐘閱讀',
    date '2024-10-20',
    '下一波限時折扣即將開跑，活動一開始，首頁就會出現倒數計時與即時折扣價，把握時間下單最划算。',
    '活動這樣玩',
    '活動期間，參與的商品會自動套用折扣，結帳時直接以折扣後的價格計算，不需要輸入任何優惠碼。',
    '「好東西不用等特價，但特價的時候買最開心。」',
    '行銷團隊',
    '活動時間與折扣品項以首頁公告為準，數量有限，建議先加入購物車，時間一到就能立刻結帳。'
  ),
  (
    '購物須知',
    '出貨與物流須知，讓你安心等收貨',
    '從下單到收貨的完整流程說明，包含出貨時間、物流查詢與注意事項。',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDhuKogbbrStjikxRIqgtHBb6lTgD7qD46-A-p4sDP9-mVMtJYA7siFi0xITatpnl6eXzgI8PXaTws96INcenz2_TQKd2KLI5u7zmqkzz_lijym1vwvmsy_a1SDBHmvmHv1ibJTl1n25fQ8hjmGcuCOnShGyDR2DoYJN5ASxUb-l-uF89jtOiNPqCgiz5lsN3ir463yEvCninQqfnKKcq5nLL0rxsMNBa4ezbsFJOVPRE3pkaskqT5fiRKDxh3dgTj9s6nX_8wXzmo',
    '購物須知',
    '3 分鐘閱讀',
    date '2024-10-15',
    '為了讓大家買得安心，我們整理了從下單、付款到出貨的完整流程，收貨前有任何問題都可以先參考這篇。',
    '出貨時間與物流',
    '完成付款後，訂單會在工作日內安排出貨；遇到連假或活動檔期，出貨時間可能稍有延後，還請耐心等候。',
    '「每一筆訂單，我們都會仔細包裝後再送出。」',
    '出貨團隊',
    '訂單狀態可在會員中心的「我的訂單」查詢，收到商品後若有任何狀況，歡迎盡快與我們聯繫。'
  ),
  (
    '會員專區',
    '加入會員，購物紀錄與訂單一次掌握',
    '註冊會員即可查詢歷史訂單、追蹤出貨進度，享有更完整的購物體驗。',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBexMkgMId63sVOsiSHUZHxfx39SIOOz-JgE7kqOpuThNwUYl_-xNkTXcCGMuV7C9OOEVX6gpA1-5Zo7luKpdg5oIvD5S36FH4JTvUFNT7l4KYj5w7cGcloddJHCAdeaUrV-VUejb__0o6ldws5spdGVqMbjeTPPaQxsFA7FpCoxBjy36ghdar7qKgECrcct0P3F0uLGZyMPzetxQBz4DBQIWRzQnOGL31F499g8cBXCmvEuRGn-Szj5R6tcAA-uOkBRknUFFs_Xfc',
    '會員專區',
    '2 分鐘閱讀',
    date '2024-10-08',
    '成為會員後，你的每一筆訂單都會完整保留，隨時可以回來查看購物紀錄與出貨進度。',
    '會員能做什麼',
    '登入後即可在會員中心查詢進行中的訂單與歷史訂單，也能更快完成下次結帳，省去重複填寫的麻煩。',
    '「讓每一次購物，都留下清楚的紀錄。」',
    '客戶服務團隊',
    '還沒有帳號嗎？只要用電子郵件就能快速註冊，馬上開始你的購物旅程。'
  )
) as seed
where not exists (select 1 from public.news);
