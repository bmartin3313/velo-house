-- Velo House Pitching: database setup for your own Supabase project
-- Paste this whole file into Supabase > SQL Editor > New query, then click Run.
-- Safe to run once on a brand-new project.

-- ========== 1. Profiles (one row per account) ==========
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  full_name  text default '',
  role       text not null default 'player' check (role in ('player','coach')),
  email      text default ''
);

-- Create a profile automatically whenever someone signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), coalesce(new.email,''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- Helper: is the signed-in person a coach?
create or replace function public.is_coach()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'coach');
$$;

-- Only coaches may change anyone's role (stops a player making himself a coach)
create or replace function public.guard_role_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- auth.uid() is empty when you run SQL yourself in the dashboard, so that is always allowed
  if new.role is distinct from old.role and auth.uid() is not null and not public.is_coach() then
    raise exception 'Only a coach can change roles';
  end if;
  return new;
end $$;

drop trigger if exists profiles_guard_role on public.profiles;
create trigger profiles_guard_role
  before update on public.profiles for each row execute function public.guard_role_change();

alter table public.profiles enable row level security;
drop policy if exists "profiles read"   on public.profiles;
drop policy if exists "profiles update" on public.profiles;
create policy "profiles read"   on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_coach());
create policy "profiles update" on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_coach());

-- ========== 2. Player data (each pitcher's plan, logs, and coach changes) ==========
create table if not exists public.player_data (
  user_id     uuid primary key references public.profiles(id) on delete cascade,
  settings    jsonb default '{}'::jsonb,
  logs        jsonb default '{}'::jsonb,
  coach_edits jsonb,
  updated_at  timestamptz default now()
);

alter table public.player_data enable row level security;
drop policy if exists "player_data read"   on public.player_data;
drop policy if exists "player_data insert" on public.player_data;
drop policy if exists "player_data update" on public.player_data;
create policy "player_data read"   on public.player_data for select to authenticated
  using (user_id = auth.uid() or public.is_coach());
create policy "player_data insert" on public.player_data for insert to authenticated
  with check (user_id = auth.uid());
create policy "player_data update" on public.player_data for update to authenticated
  using (user_id = auth.uid() or public.is_coach());

-- ========== 3. Team grip library (shared by all coaches) ==========
create table if not exists public.team_grips (
  id  text primary key,
  t   text default 'FB',
  n   text default '',
  cue text default '',
  url text default '',
  d   text default ''
);

alter table public.team_grips enable row level security;
drop policy if exists "grips read"   on public.team_grips;
drop policy if exists "grips insert" on public.team_grips;
drop policy if exists "grips delete" on public.team_grips;
create policy "grips read"   on public.team_grips for select to authenticated using (true);
create policy "grips insert" on public.team_grips for insert to authenticated with check (public.is_coach());
create policy "grips delete" on public.team_grips for delete to authenticated using (public.is_coach());

-- ========== 4. Video clips (private storage; each pitcher has his own folder) ==========
insert into storage.buckets (id, name, public) values ('videos','videos', false)
  on conflict (id) do nothing;

drop policy if exists "videos read"   on storage.objects;
drop policy if exists "videos upload" on storage.objects;
drop policy if exists "videos delete" on storage.objects;
create policy "videos read" on storage.objects for select to authenticated
  using (bucket_id = 'videos' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_coach()));
create policy "videos upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'videos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "videos delete" on storage.objects for delete to authenticated
  using (bucket_id = 'videos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ========== 5. Make yourself the first coach ==========
-- After you create your account in the app, run this line once (with your email):
-- update public.profiles set role = 'coach' where email = 'YOUR-EMAIL-HERE';
