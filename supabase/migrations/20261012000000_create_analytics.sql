create table if not exists public.analytics_events (
  id uuid primary key,
  created_at timestamptz not null default now(),
  install_id uuid not null,
  event_name text not null check (
    event_name in (
      'app_open',
      'style_selected',
      'character_selected',
      'basic_variant_selected'
    )
  ),
  app_version text not null check (char_length(app_version) between 1 and 32),
  style text check (style is null or style in ('basic', 'animal')),
  selection text check (selection is null or char_length(selection) between 1 and 64),
  platform text not null default 'macos' check (platform = 'macos')
);

alter table public.analytics_events enable row level security;

revoke all on table public.analytics_events from anon, authenticated;
grant insert on table public.analytics_events to anon;

drop policy if exists "Allow anonymous analytics inserts" on public.analytics_events;
create policy "Allow anonymous analytics inserts"
on public.analytics_events
for insert
to anon
with check (
  event_name in (
    'app_open',
    'style_selected',
    'character_selected',
    'basic_variant_selected'
  )
  and app_version <> ''
  and (style is null or style in ('basic', 'animal'))
  and (selection is null or char_length(selection) <= 64)
  and platform = 'macos'
);

create index if not exists analytics_events_created_at_idx
on public.analytics_events (created_at desc);

create index if not exists analytics_events_install_id_idx
on public.analytics_events (install_id);

create or replace view public.analytics_daily_summary as
select
  date_trunc('day', created_at) as day,
  event_name,
  style,
  selection,
  count(*) as event_count,
  count(distinct install_id) as unique_installs
from public.analytics_events
group by 1, 2, 3, 4;

revoke all on table public.analytics_daily_summary from anon, authenticated;

comment on table public.analytics_events is
'Anonymous, opt-in product usage events for On Air Companion. No Zoom device state or personal account data is stored.';
