-- Ejecuta todo este archivo en Supabase > SQL Editor > New query.
-- ReUsa: perfiles de publicación, objetos, alquileres y fotografías.

create extension if not exists pgcrypto;

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  owner_name text not null,
  title text not null check (char_length(title) between 2 and 70),
  category text not null,
  price_per_day numeric(10,2) not null check (price_per_day > 0),
  location text not null,
  description text not null check (char_length(description) between 10 and 500),
  image_url text not null,
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists listings_owner_id_idx on public.listings(owner_id);
create index if not exists listings_available_created_idx on public.listings(is_available, created_at desc);

create table if not exists public.rentals (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete restrict,
  renter_id uuid not null references auth.users(id) on delete cascade,
  renter_name text not null,
  start_date date not null,
  end_date date not null,
  days integer not null check (days > 0),
  total numeric(10,2) not null check (total > 0),
  commission numeric(10,2) not null check (commission >= 0),
  owner_net numeric(10,2) not null check (owner_net >= 0),
  status text not null default 'Solicitado' check (status in ('Solicitado','Aceptado','Rechazado','Completado')),
  created_at timestamptz not null default now(),
  constraint rental_dates_valid check (end_date >= start_date)
);

create index if not exists rentals_listing_id_idx on public.rentals(listing_id);
create index if not exists rentals_renter_id_idx on public.rentals(renter_id);

alter table public.listings enable row level security;
alter table public.rentals enable row level security;

drop policy if exists "Anyone can view available listings" on public.listings;
create policy "Anyone can view available listings"
  on public.listings for select
  using (is_available = true or owner_id = auth.uid());

drop policy if exists "Authenticated users create own listings" on public.listings;
create policy "Authenticated users create own listings"
  on public.listings for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists "Owners update own listings" on public.listings;
create policy "Owners update own listings"
  on public.listings for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "Renters and listing owners view rentals" on public.rentals;
create policy "Renters and listing owners view rentals"
  on public.rentals for select to authenticated
  using (
    renter_id = auth.uid()
    or exists (select 1 from public.listings l where l.id = listing_id and l.owner_id = auth.uid())
  );

drop policy if exists "Users request rentals for other owners listings" on public.rentals;
create policy "Users request rentals for other owners listings"
  on public.rentals for insert to authenticated
  with check (
    renter_id = auth.uid()
    and exists (select 1 from public.listings l where l.id = listing_id and l.owner_id <> auth.uid() and l.is_available = true)
  );

drop policy if exists "Listing owners update rental status" on public.rentals;
create policy "Listing owners update rental status"
  on public.rentals for update to authenticated
  using (exists (select 1 from public.listings l where l.id = listing_id and l.owner_id = auth.uid()))
  with check (exists (select 1 from public.listings l where l.id = listing_id and l.owner_id = auth.uid()));

-- Bucket público para que las fotos de publicaciones se puedan mostrar en el catálogo.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-photos', 'product-photos', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 8388608, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Public can view product photos" on storage.objects;
create policy "Public can view product photos"
  on storage.objects for select
  using (bucket_id = 'product-photos');

drop policy if exists "Users upload photos to their own folder" on storage.objects;
create policy "Users upload photos to their own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users delete photos in their own folder" on storage.objects;
create policy "Users delete photos in their own folder"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-photos' and (storage.foldername(name))[1] = auth.uid()::text);
