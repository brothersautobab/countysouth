-- ============================================================
--  County South Business Brokers — Supabase Schema
--  Run this in the Supabase SQL Editor to set up your database
-- ============================================================

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ────────────────────────────────────────
--  LISTINGS table
-- ────────────────────────────────────────
create table listings (
  id            uuid primary key default uuid_generate_v4(),
  listing_number text not null unique,          -- e.g. "CS98191"
  title         text not null,                  -- e.g. "C-Store & Gas Station with Property"
  business_type text not null,                  -- e.g. "Convenience Store / Gas"
  city          text not null,
  state         char(2) not null,               -- "NC" or "SC"
  asking_price  numeric(12,2) not null,
  annual_sales  numeric(12,2),                  -- null = NDA required
  monthly_rent  numeric(10,2),
  fuel_gallons  integer,                        -- monthly gallons if gas station
  property_included  boolean default false,
  owner_financing    boolean default false,
  sba_eligible       boolean default true,
  reason_for_selling text,
  description   text,
  status        text default 'active'           -- 'active' | 'pending' | 'sold'
                check (status in ('active','pending','sold')),
  nda_required  boolean default true,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- ────────────────────────────────────────
--  Auto-update updated_at on any change
-- ────────────────────────────────────────
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger listings_updated_at
  before update on listings
  for each row execute procedure set_updated_at();

-- ────────────────────────────────────────
--  Row Level Security — public read,
--  authenticated write (brokers only)
-- ────────────────────────────────────────
alter table listings enable row level security;

-- Anyone can read active listings
create policy "Public can view active listings"
  on listings for select
  using (status = 'active');

-- Only authenticated users (brokers) can insert/update/delete
create policy "Brokers can manage listings"
  on listings for all
  using (auth.role() = 'authenticated');

-- ────────────────────────────────────────
--  Seed data — the listings from our mockup
-- ────────────────────────────────────────
insert into listings (
  listing_number, title, business_type, city, state,
  asking_price, annual_sales, property_included, owner_financing,
  sba_eligible, reason_for_selling, description, status
) values
(
  'CS98191',
  'C-Store & Gas Station with Real Property',
  'Convenience Store / Gas',
  'Burnsville', 'NC',
  3200000, null, true, false, true,
  'Retirement',
  'Well-established convenience store and gas station in the scenic mountain region of Burnsville, NC. The sale includes real property — a significant value-add. The current owner is retiring after many successful years. Full financials, fuel volume, and supplier agreements available under NDA to qualified buyers.',
  'active'
),
(
  'FS97702',
  'Established Restaurant — Prime Location',
  'Food Service',
  'Charlotte', 'NC',
  340000, 719768, false, false, false,
  'Owner relocating',
  'Established restaurant in a prime Charlotte location with strong and consistent annual sales. The space operates on a favorable lease at $3,550/month. Full financial package available to qualified buyers after NDA.',
  'active'
),
(
  'SV08204',
  'Construction Company with Active Contracts',
  'Construction',
  'Fort Mill', 'SC',
  1300000, 1114525, false, false, true,
  'Partnership dissolution',
  'Profitable construction company with active contracts and a strong recurring client base in the booming Fort Mill, SC market. Real property is available separately. Equipment and licensed workforce included in the sale.',
  'active'
),
(
  'SV08203',
  'Profitable Service Business — Low Overhead',
  'Service',
  'Charlotte', 'NC',
  190000, 190000, false, false, true,
  'Retirement',
  'Profitable service business in the Charlotte metro with low overhead and consistent annual revenue. The business operates from a small leased space at $2,652/month with minimal staff and strong margins. An ideal acquisition for an owner-operator.',
  'active'
),
(
  'CS98230',
  'High-Volume Gas Station — 60K Gal/Mo',
  'Convenience Store / Gas',
  'Fayetteville', 'NC',
  159000, 2500000, false, false, true,
  'Owner pursuing other ventures',
  'High-volume gas station pumping approximately 60,000 gallons per month with strong annual sales. Leased location with favorable rent terms. Full details including supplier agreement and fuel margins available under NDA.',
  'active'
),
(
  'CP97587',
  'Commercial Investment Property',
  'Commercial Property',
  'Claremont', 'NC',
  96000, null, true, false, true,
  'Portfolio liquidation',
  'Commercial investment property in Claremont, NC. Full details available to qualified buyers. Contact broker for more information.',
  'active'
),
(
  'SV08197',
  'Service Business — Established Customer Base',
  'Service',
  'Lenoir', 'NC',
  250000, 198960, false, false, true,
  'Retirement',
  'Well-established service business in Lenoir, NC with a loyal customer base built over many years. Low overhead and consistent revenue make this an attractive acquisition.',
  'active'
);

-- ────────────────────────────────────────
--  Helpful indexes for common queries
-- ────────────────────────────────────────
create index listings_status_idx on listings(status);
create index listings_state_idx on listings(state);
create index listings_type_idx on listings(business_type);
create index listings_price_idx on listings(asking_price);
