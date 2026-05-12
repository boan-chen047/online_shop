create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id),
  slug text unique,
  name text not null,
  description text,
  price numeric(10, 2) not null check (price >= 0),
  original_price numeric(10, 2) check (original_price is null or original_price >= price),
  tag text,
  status text not null default 'draft' check (status in ('draft', 'active', 'archived')),
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  alt text,
  sort_order int not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.product_specs (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  label text not null,
  value text not null,
  sort_order int not null default 0
);

create table if not exists public.inventory (
  product_id uuid primary key references public.products(id) on delete cascade,
  quantity int not null default 0 check (quantity >= 0),
  reserved_quantity int not null default 0 check (reserved_quantity >= 0),
  updated_at timestamptz not null default now(),
  check (reserved_quantity <= quantity)
);

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  selected boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid', 'paid', 'failed', 'refunded')),
  order_status text not null default 'created' check (order_status in ('created', 'shipping', 'received')),
  subtotal numeric(10, 2) not null default 0 check (subtotal >= 0),
  shipping_fee numeric(10, 2) not null default 0 check (shipping_fee >= 0),
  discount_amount numeric(10, 2) not null default 0 check (discount_amount >= 0),
  total numeric(10, 2) not null default 0 check (total >= 0),
  currency text not null default 'TWD',
  placed_at timestamptz not null default now(),
  paid_at timestamptz,
  shipped_at timestamptz,
  received_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  product_image_url text,
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  quantity int not null check (quantity > 0),
  line_total numeric(10, 2) not null check (line_total >= 0),
  created_at timestamptz not null default now()
);

create index if not exists categories_active_sort_idx on public.categories(is_active, sort_order);
create index if not exists products_category_id_idx on public.products(category_id);
create index if not exists products_status_sort_idx on public.products(status, sort_order, created_at desc);
create index if not exists products_status_created_at_idx on public.products(status, created_at desc);
create index if not exists products_price_idx on public.products(price);
create index if not exists product_images_product_sort_idx on public.product_images(product_id, sort_order);
create index if not exists product_specs_product_sort_idx on public.product_specs(product_id, sort_order);
create index if not exists cart_items_user_id_idx on public.cart_items(user_id);
create index if not exists orders_user_created_at_idx on public.orders(user_id, created_at desc);
create index if not exists order_items_order_id_idx on public.order_items(order_id);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_specs enable row level security;
alter table public.inventory enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "categories_read_active" on public.categories;
create policy "categories_read_active"
on public.categories
for select
to anon, authenticated
using (is_active = true);

drop policy if exists "products_read_active" on public.products;
create policy "products_read_active"
on public.products
for select
to anon, authenticated
using (status = 'active');

drop policy if exists "product_images_read_active_products" on public.product_images;
create policy "product_images_read_active_products"
on public.product_images
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = product_images.product_id
      and products.status = 'active'
  )
);

drop policy if exists "product_specs_read_active_products" on public.product_specs;
create policy "product_specs_read_active_products"
on public.product_specs
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = product_specs.product_id
      and products.status = 'active'
  )
);

drop policy if exists "cart_items_select_own" on public.cart_items;
create policy "cart_items_select_own"
on public.cart_items
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "cart_items_insert_own" on public.cart_items;
create policy "cart_items_insert_own"
on public.cart_items
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "cart_items_update_own" on public.cart_items;
create policy "cart_items_update_own"
on public.cart_items
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "cart_items_delete_own" on public.cart_items;
create policy "cart_items_delete_own"
on public.cart_items
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own"
on public.orders
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "order_items_select_own_orders" on public.order_items;
create policy "order_items_select_own_orders"
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
);

drop trigger if exists set_categories_updated_at on public.categories;
create trigger set_categories_updated_at
before update on public.categories
for each row
execute function public.set_updated_at();

drop trigger if exists set_products_updated_at on public.products;
create trigger set_products_updated_at
before update on public.products
for each row
execute function public.set_updated_at();

drop trigger if exists set_inventory_updated_at on public.inventory;
create trigger set_inventory_updated_at
before update on public.inventory
for each row
execute function public.set_updated_at();

drop trigger if exists set_cart_items_updated_at on public.cart_items;
create trigger set_cart_items_updated_at
before update on public.cart_items
for each row
execute function public.set_updated_at();

drop trigger if exists set_orders_updated_at on public.orders;
create trigger set_orders_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

create or replace function public.set_order_closed_at()
returns trigger
language plpgsql
as $$
begin
  if new.order_status = 'received' and old.order_status is distinct from 'received' then
    new.received_at = coalesce(new.received_at, now());
    new.closed_at = coalesce(new.closed_at, new.received_at + interval '7 days');
  end if;

  return new;
end;
$$;

drop trigger if exists set_order_closed_at_on_received on public.orders;
create trigger set_order_closed_at_on_received
before update on public.orders
for each row
execute function public.set_order_closed_at();

create or replace function public.create_order_from_cart()
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
    total
  )
  values (
    current_user_id,
    'unpaid',
    'created',
    computed_subtotal,
    0,
    0,
    computed_subtotal
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

grant execute on function public.create_order_from_cart() to authenticated;
