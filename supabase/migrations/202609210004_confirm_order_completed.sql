-- 顧客提前結束 7 天鑑賞期：把 closed_at 設為 now()，該訂單即視為已完結。
-- security definer：只允許操作「自己的、已簽收(received)、且仍在鑑賞期內」的訂單。
create or replace function public.confirm_order_completed(p_order_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_order public.orders%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_order from public.orders where id = p_order_id;
  if not found then
    return 'not_found';
  end if;

  if v_order.user_id <> v_user then
    raise exception 'Forbidden';
  end if;

  if v_order.order_status <> 'received' then
    return 'not_received';
  end if;

  if v_order.closed_at is not null and now() >= v_order.closed_at then
    return 'already_completed';
  end if;

  update public.orders
    set closed_at = now(), updated_at = now()
    where id = p_order_id;

  return 'completed';
end;
$$;

grant execute on function public.confirm_order_completed(uuid) to authenticated;
