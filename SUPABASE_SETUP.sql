-- SMART QC — Supabase production setup
-- 1) Run this file in Supabase SQL Editor.
-- 2) Create staff accounts in Authentication > Users.
-- 3) Add each user's UUID to smartqc_workspace_members (see example at bottom).
-- IMPORTANT: never expose a service_role/secret key in the browser.

create table if not exists public.smartqc_workspace_members (
  workspace_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'staff' check (role in ('admin','staff','viewer')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.smartqc_shared_state (
  workspace_id text primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) default auth.uid()
);

alter table public.smartqc_workspace_members enable row level security;
alter table public.smartqc_shared_state enable row level security;

revoke all on table public.smartqc_workspace_members from anon, authenticated;
revoke all on table public.smartqc_shared_state from anon, authenticated;
grant select on table public.smartqc_workspace_members to authenticated;
grant select, insert, update on table public.smartqc_shared_state to authenticated;

drop policy if exists smartqc_members_select_self on public.smartqc_workspace_members;
create policy smartqc_members_select_self
on public.smartqc_workspace_members for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists smartqc_state_select_member on public.smartqc_shared_state;
create policy smartqc_state_select_member
on public.smartqc_shared_state for select
to authenticated
using (exists (
  select 1 from public.smartqc_workspace_members m
  where m.workspace_id = smartqc_shared_state.workspace_id
    and m.user_id = (select auth.uid())
    and m.active = true
));

drop policy if exists smartqc_state_insert_member on public.smartqc_shared_state;
create policy smartqc_state_insert_member
on public.smartqc_shared_state for insert
to authenticated
with check (exists (
  select 1 from public.smartqc_workspace_members m
  where m.workspace_id = smartqc_shared_state.workspace_id
    and m.user_id = (select auth.uid())
    and m.active = true
    and m.role in ('admin','staff')
));

drop policy if exists smartqc_state_update_member on public.smartqc_shared_state;
create policy smartqc_state_update_member
on public.smartqc_shared_state for update
to authenticated
using (exists (
  select 1 from public.smartqc_workspace_members m
  where m.workspace_id = smartqc_shared_state.workspace_id
    and m.user_id = (select auth.uid())
    and m.active = true
    and m.role in ('admin','staff')
))
with check (exists (
  select 1 from public.smartqc_workspace_members m
  where m.workspace_id = smartqc_shared_state.workspace_id
    and m.user_id = (select auth.uid())
    and m.active = true
    and m.role in ('admin','staff')
));

-- Realtime cross-device updates.
do $$
begin
  alter publication supabase_realtime add table public.smartqc_shared_state;
exception when duplicate_object then null;
end $$;

-- After creating a user in Authentication > Users, run one row like this:
-- insert into public.smartqc_workspace_members (workspace_id, user_id, role)
-- values ('smartqc-qyh-shared', 'USER_UUID_HERE', 'admin');
--
-- Staff who can enter/edit QC: role = 'staff'
-- Read-only users: role = 'viewer'
