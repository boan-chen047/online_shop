-- Test data seed for online_shop.
-- Safe to rerun in a test database. It upserts catalog data by slug and refreshes
-- images/specs/inventory for the seeded products.
--
-- The final section promotes the provided test account to admin_level_2 by email.
-- Change the email if you want a different account to be the level 2 administrator.

begin;

insert into public.categories (slug, name, sort_order, is_active)
values
  ('snacks', '零食', 10, true),
  ('beverages', '飲料', 20, true),
  ('daily', '生活用品', 30, true),
  ('electronics', '電子設備', 40, true),
  ('watches', '手錶', 50, true)
on conflict (slug) do update
set
  name = excluded.name,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

create temporary table seed_products (
  slug text primary key,
  category_slug text not null,
  name text not null,
  description text not null,
  price numeric(10, 2) not null,
  original_price numeric(10, 2),
  tag text,
  status text not null,
  sort_order int not null,
  image_url text not null,
  spec_1_label text not null,
  spec_1_value text not null,
  spec_2_label text not null,
  spec_2_value text not null,
  spec_3_label text not null,
  spec_3_value text not null,
  quantity int not null,
  reserved_quantity int not null default 0
) on commit drop;

insert into seed_products (
  slug, category_slug, name, description, price, original_price, tag, status, sort_order,
  image_url, spec_1_label, spec_1_value, spec_2_label, spec_2_value, spec_3_label, spec_3_value,
  quantity, reserved_quantity
)
values
  ('yilan-scallion-cracker', 'snacks', '宜蘭三星蔥薄餅', '酥脆薄餅帶有三星蔥香，適合下午茶或追劇點心。', 89, 109, '人氣', 'active', 10, 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg', '產地', '台灣宜蘭', '重量', '180g', '保存', '常溫', 45, 3),
  ('tainan-shrimp-cracker', 'snacks', '台南蝦餅家庭包', '薄脆蝦餅帶海味香氣，家庭聚會與辦公室分享都方便。', 120, null, null, 'active', 20, 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg', '產地', '台灣台南', '重量', '240g', '口味', '原味', 38, 2),
  ('brown-sugar-rice-puff', 'snacks', '黑糖米香小包', '古早味黑糖米香，獨立小包裝適合放進便當袋。', 75, null, null, 'active', 30, 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg', '包裝', '10入', '甜度', '中等', '保存', '常溫', 64, 5),
  ('seaweed-egg-roll', 'snacks', '海苔雞蛋捲', '酥鬆蛋捲加入海苔香氣，是台灣常見伴手禮點心。', 160, 188, '新品', 'active', 40, 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg', '包裝', '12入', '口味', '海苔', '過敏原', '蛋、麩質', 28, 1),
  ('spicy-broad-bean', 'snacks', '麻辣蠶豆酥', '香辣涮嘴的蠶豆酥，適合宵夜、下酒或聚會零食。', 69, null, null, 'active', 50, 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg', '辣度', '中辣', '重量', '160g', '保存', '常溫', 72, 8),
  ('pineapple-cake-box', 'snacks', '鳳梨酥禮盒', '酸甜鳳梨餡搭配酥香外皮，適合送禮與節慶備品。', 360, 420, '送禮', 'active', 60, 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg', '包裝', '12入', '產地', '台灣', '保存', '常溫', 20, 0),
  ('alishan-cold-brew-tea', 'beverages', '阿里山冷泡茶', '清爽回甘的冷泡茶，適合夏天冰箱常備。', 99, null, '人氣', 'active', 70, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg', '容量', '580ml x 4', '茶種', '高山烏龍', '甜度', '無糖', 50, 3),
  ('taiwan-black-tea', 'beverages', '台茶18號紅茶', '帶有淡淡薄荷與肉桂香氣的台灣紅茶，可熱飲也可冷泡。', 135, null, null, 'active', 80, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg', '茶種', '紅玉紅茶', '包裝', '茶包20入', '產地', '南投魚池', 42, 2),
  ('soy-milk-family-pack', 'beverages', '無糖豆漿家庭號', '早餐店風味無糖豆漿，適合早餐、運動後補充。', 68, null, null, 'active', 90, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg', '容量', '936ml x 2', '糖分', '無糖', '保存', '冷藏', 36, 4),
  ('wintermelon-lemon', 'beverages', '冬瓜檸檬飲', '冬瓜茶加入檸檬酸香，冰鎮後更適合台灣炎熱天氣。', 45, null, null, 'active', 100, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg', '容量', '330ml x 6', '甜度', '微甜', '保存', '常溫', 58, 6),
  ('sparkling-plum-drink', 'beverages', '梅子氣泡飲', '帶梅子鹹甜香氣的氣泡飲，清爽解膩。', 79, 95, '季節', 'active', 110, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg', '容量', '330ml x 6', '口味', '梅子', '甜度', '微甜', 31, 1),
  ('drip-coffee-taiwan', 'beverages', '台灣濾掛咖啡', '中焙濾掛咖啡，適合辦公室與居家早晨。', 220, null, null, 'active', 120, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg', '包裝', '12入', '焙度', '中焙', '風味', '堅果、可可', 27, 0),
  ('bamboo-tissue-box', 'daily', '竹纖維抽取式衛生紙', '柔韌竹纖維衛生紙，適合家庭日常囤貨。', 199, 239, '補貨', 'active', 130, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '包裝', '24包', '材質', '竹纖維', '用途', '家用', 40, 5),
  ('kitchen-cleaning-cloth', 'daily', '廚房去油抹布組', '吸水快乾的廚房抹布，適合流理台、餐桌與瓦斯爐周邊。', 129, null, null, 'active', 140, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '數量', '6入', '材質', '超細纖維', '清洗', '可水洗', 55, 3),
  ('stainless-lunch-box', 'daily', '不鏽鋼便當盒', '耐用不鏽鋼便當盒，適合通勤上班與學生午餐。', 299, 350, null, 'active', 150, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '容量', '900ml', '材質', '304不鏽鋼', '隔層', '可拆式', 22, 1),
  ('folding-umbrella', 'daily', '抗UV折疊傘', '台灣午後陣雨與烈日都能應對的輕量折疊傘。', 259, null, '熱銷', 'active', 160, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '傘布', '抗UV', '重量', '280g', '顏色', '深藍', 18, 0),
  ('laundry-detergent-refill', 'daily', '洗衣精補充包', '低泡易沖洗洗衣精補充包，適合一般家庭日常衣物。', 169, null, null, 'active', 170, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '容量', '1800ml', '香味', '清新皂香', '用途', '一般衣物', 48, 8),
  ('low-stock-storage-box', 'daily', '低庫存收納盒', '特意設定低庫存，用來測試管理者庫存警示。', 89, null, '低庫存', 'active', 180, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '容量', '12L', '材質', 'PP塑膠', '用途', '庫存測試', 2, 0),
  ('usb-c-fast-charger', 'electronics', 'USB-C 快充頭', '支援筆電與手機的USB-C快充頭，適合通勤包常備。', 590, 690, '人氣', 'active', 190, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '功率', '65W', '接口', 'USB-C', '保固', '一年', 25, 2),
  ('braided-charging-cable', 'electronics', '編織充電線', '耐拉扯編織線材，支援手機、平板日常充電。', 199, null, null, 'active', 200, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '長度', '1.5m', '接口', 'USB-C', '材質', '尼龍編織', 80, 10),
  ('portable-power-bank', 'electronics', '行動電源10000mAh', '輕薄行動電源，適合通勤、旅遊與外出一整天。', 799, 899, null, 'active', 210, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '容量', '10000mAh', '輸出', '20W', '接口', 'USB-C', 34, 4),
  ('bluetooth-speaker-small', 'electronics', '小型藍牙喇叭', '小客廳與房間適用的藍牙喇叭，聲音清楚不佔空間。', 880, null, '新品', 'active', 220, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '連線', 'Bluetooth 5.3', '防水', 'IPX5', '續航', '12小時', 16, 1),
  ('wireless-mouse-office', 'electronics', '辦公無線滑鼠', '安靜按鍵與穩定連線，適合辦公室與居家工作。', 349, null, null, 'active', 230, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '連線', '2.4GHz', '按鍵', '靜音', '電池', 'AA電池', 44, 0),
  ('noise-cancel-earbuds', 'electronics', '降噪真無線耳機', '通勤捷運與咖啡廳工作都適合的入耳式降噪耳機。', 2490, 2990, '熱銷', 'active', 240, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '降噪', '主動式', '續航', '32小時', '充電', 'USB-C', 0, 0),
  ('minimal-steel-watch', 'watches', '簡約鋼帶手錶', '乾淨錶盤搭配不鏽鋼錶帶，適合日常通勤穿搭。', 1680, 1980, null, 'active', 250, 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI', '錶徑', '38mm', '錶帶', '不鏽鋼', '防水', '5ATM', 15, 1),
  ('canvas-field-watch', 'watches', '帆布軍風手錶', '高對比數字面盤與帆布錶帶，戶外與休閒穿搭都合適。', 1280, null, null, 'active', 260, 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI', '錶徑', '40mm', '錶帶', '帆布', '機芯', '石英', 18, 0),
  ('student-digital-watch', 'watches', '學生電子錶', '輕量電子錶含鬧鐘、碼錶與夜光，適合學生族群。', 590, null, null, 'active', 270, 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI', '功能', '鬧鐘/碼錶', '重量', '38g', '防水', '生活防水', 32, 2),
  ('solar-commuter-watch', 'watches', '太陽能通勤錶', '太陽能充電搭配清楚刻度，日常通勤免常換電池。', 2280, null, '新品', 'active', 280, 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI', '充電', '太陽能', '錶徑', '39mm', '防水', '10ATM', 9, 0),
  ('ceramic-dial-watch', 'watches', '陶瓷面盤手錶', '草稿商品，用來測試管理者可見、一般使用者不可見的商品狀態。', 3180, null, '草稿', 'draft', 290, 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI', '狀態', '草稿', '用途', '管理測試', '機芯', '石英', 5, 0),
  ('archived-cable-kit', 'electronics', '封存線材組', '封存商品，用來測試管理者狀態檢視與公開列表隱藏。', 250, null, '封存', 'archived', 300, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '狀態', '封存', '接口', 'USB-C', '用途', '管理測試', 8, 0),
  ('draft-smart-scale', 'electronics', '草稿智慧體重計', '草稿測試商品，方便檢查定價、狀態與庫存管理流程。', 990, null, '草稿', 'draft', 310, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I', '狀態', '草稿', '用途', '管理測試', '電源', 'AAA電池', 6, 0),
  ('taiwan-rice-pack', 'daily', '台東米家庭包', '台東白米家庭包，適合一般家庭日常煮飯。', 289, 329, '家庭號', 'active', 320, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw', '重量', '3kg', '產地', '台灣台東', '保存', '陰涼乾燥', 33, 2);

insert into public.products (
  category_id, slug, name, description, price, original_price, tag, status, sort_order
)
select
  categories.id,
  seed_products.slug,
  seed_products.name,
  seed_products.description,
  seed_products.price,
  seed_products.original_price,
  seed_products.tag,
  seed_products.status,
  seed_products.sort_order
from seed_products
join public.categories on categories.slug = seed_products.category_slug
on conflict (slug) do update
set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  original_price = excluded.original_price,
  tag = excluded.tag,
  status = excluded.status,
  sort_order = excluded.sort_order,
  updated_at = now();

delete from public.product_images
using public.products
join seed_products on seed_products.slug = products.slug
where product_images.product_id = products.id;

insert into public.product_images (product_id, image_url, alt, sort_order, is_primary)
select
  products.id,
  seed_products.image_url,
  seed_products.name,
  0,
  true
from seed_products
join public.products on products.slug = seed_products.slug;

delete from public.product_specs
using public.products
join seed_products on seed_products.slug = products.slug
where product_specs.product_id = products.id;

insert into public.product_specs (product_id, label, value, sort_order)
select products.id, seed_products.spec_1_label, seed_products.spec_1_value, 10
from seed_products
join public.products on products.slug = seed_products.slug
union all
select products.id, seed_products.spec_2_label, seed_products.spec_2_value, 20
from seed_products
join public.products on products.slug = seed_products.slug
union all
select products.id, seed_products.spec_3_label, seed_products.spec_3_value, 30
from seed_products
join public.products on products.slug = seed_products.slug;

insert into public.inventory (product_id, quantity, reserved_quantity)
select
  products.id,
  seed_products.quantity,
  seed_products.reserved_quantity
from seed_products
join public.products on products.slug = seed_products.slug
on conflict (product_id) do update
set
  quantity = excluded.quantity,
  reserved_quantity = excluded.reserved_quantity,
  updated_at = now();

insert into public.user_profile (
  id,
  email,
  display_name,
  avatar_url,
  provider,
  last_sign_in_at
)
select
  users.id,
  users.email,
  coalesce(users.raw_user_meta_data ->> 'full_name', users.raw_user_meta_data ->> 'name', split_part(users.email, '@', 1)),
  users.raw_user_meta_data ->> 'avatar_url',
  users.raw_app_meta_data ->> 'provider',
  users.last_sign_in_at
from auth.users
where users.email = 'boan931004@gmail.com'
on conflict (id) do update
set
  email = excluded.email,
  display_name = coalesce(excluded.display_name, public.user_profile.display_name),
  avatar_url = coalesce(excluded.avatar_url, public.user_profile.avatar_url),
  provider = coalesce(excluded.provider, public.user_profile.provider),
  last_sign_in_at = excluded.last_sign_in_at,
  updated_at = now();

update public.user_profile
set
  role = 'admin_level_2',
  account_status = 'active',
  deleted_at = null,
  updated_at = now()
where email = 'boan931004@gmail.com';

insert into public.cart_items (user_id, product_id, quantity, selected)
select user_profile.id, products.id, cart_seed.quantity, cart_seed.selected
from public.user_profile
cross join (
  values
    ('yilan-scallion-cracker', 1, true),
    ('usb-c-fast-charger', 1, true),
    ('low-stock-storage-box', 1, false)
) as cart_seed(product_slug, quantity, selected)
join public.products on products.slug = cart_seed.product_slug
where user_profile.email = 'boan931004@gmail.com'
on conflict (user_id, product_id) do update
set
  quantity = excluded.quantity,
  selected = excluded.selected,
  updated_at = now();

commit;
