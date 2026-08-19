alter table public.orders
  add column if not exists recipient_name text,
  add column if not exists recipient_phone text,
  add column if not exists shipping_address text,
  add column if not exists note text;

drop function if exists public.create_order_from_cart();

create or replace function public.create_order_from_cart(
  p_recipient_name text default null,
  p_recipient_phone text default null,
  p_shipping_address text default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_order_id uuid;
  computed_subtotal numeric(10, 2);
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.cart_items
    where user_id = current_user_id
      and selected = true
  ) then
    raise exception 'No selected cart items';
  end if;

  if exists (
    select 1
    from public.cart_items ci
    join public.products p on p.id = ci.product_id
    left join public.inventory i on i.product_id = p.id
    where ci.user_id = current_user_id
      and ci.selected = true
      and (
        p.status <> 'active'
        or i.product_id is null
        or (i.quantity - i.reserved_quantity) < ci.quantity
      )
  ) then
    raise exception 'One or more selected items are unavailable';
  end if;

  select coalesce(sum(p.price * ci.quantity), 0)
  into computed_subtotal
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  where ci.user_id = current_user_id
    and ci.selected = true
    and p.status = 'active';

  insert into public.orders (
    user_id,
    payment_status,
    order_status,
    subtotal,
    shipping_fee,
    discount_amount,
    total,
    recipient_name,
    recipient_phone,
    shipping_address,
    note
  )
  values (
    current_user_id,
    'unpaid',
    'created',
    computed_subtotal,
    0,
    0,
    computed_subtotal,
    p_recipient_name,
    p_recipient_phone,
    p_shipping_address,
    p_note
  )
  returning id into new_order_id;

  insert into public.order_items (
    order_id,
    product_id,
    product_name,
    product_image_url,
    unit_price,
    quantity,
    line_total
  )
  select
    new_order_id,
    p.id,
    p.name,
    primary_image.image_url,
    p.price,
    ci.quantity,
    p.price * ci.quantity
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  left join lateral (
    select pi.image_url
    from public.product_images pi
    where pi.product_id = p.id
    order by pi.is_primary desc, pi.sort_order asc
    limit 1
  ) primary_image on true
  where ci.user_id = current_user_id
    and ci.selected = true
    and p.status = 'active';

  update public.inventory i
  set quantity = i.quantity - ci.quantity
  from public.cart_items ci
  where ci.user_id = current_user_id
    and ci.selected = true
    and ci.product_id = i.product_id;

  delete from public.cart_items
  where user_id = current_user_id
    and selected = true;

  return new_order_id;
end;
$$;

grant execute on function public.create_order_from_cart(text, text, text, text) to authenticated;
