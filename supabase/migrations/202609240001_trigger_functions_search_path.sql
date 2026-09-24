-- 安全硬化：兩個 trigger 函式未固定 search_path（Supabase advisor lint 0011
-- function_search_path_mutable）。固定為空字串，函式內只用 pg_catalog 內建
-- （now()、interval），不受呼叫端 search_path 影響。
alter function public.set_order_closed_at() set search_path = '';
alter function public.set_updated_at() set search_path = '';
