-- ============================================================================
-- Passeport des Savoirs — schéma et droits
--
-- Installé dans le projet Supabase déjà utilisé par l'Officer Academy.
-- Toutes les tables sont préfixées « pds_ » : rien n'est partagé avec l'Academy
-- en dehors de auth.users, si bien qu'une personne présente dans les deux
-- outils s'y connecte avec le même identifiant et le même mot de passe.
--
-- Les droits sont appliqués par la base (RLS), pas par l'interface : même en
-- appelant l'API directement, personne ne voit ni ne modifie ce qui ne le
-- regarde pas.
-- ============================================================================

-- ---------------------------------------------------------------- Hôtels ----
create table if not exists public.pds_hotels (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  created_at  timestamptz not null default now()
);

-- -------------------------------------------------------------- Profils ----
-- L'id est celui de auth.users. Pas de clé étrangère : l'Academy supprime des
-- comptes auth lors de son anonymisation, et cela ne doit pas emporter les
-- passeports au passage.
create table if not exists public.pds_profiles (
  id            uuid primary key,
  email         text not null,
  nom           text not null default '',
  role          text not null default 'collaborateur'
                check (role in ('collaborateur', 'officer', 'proprietaire', 'admin')),
  hotel_id      uuid references public.pds_hotels(id) on delete set null,
  status        text not null default 'invite'
                check (status in ('invite', 'actif', 'desactive')),
  invited_at    timestamptz not null default now(),
  activated_at  timestamptz,
  created_at    timestamptz not null default now()
);
create index if not exists pds_profiles_hotel_idx on public.pds_profiles(hotel_id);

-- ------------------------------------------------------------ Passeports ----
create table if not exists public.pds_passports (
  id             uuid primary key default gen_random_uuid(),
  service        text not null,
  hotel_id       uuid references public.pds_hotels(id) on delete set null,
  owner_id       uuid references public.pds_profiles(id) on delete set null,
  nom            text not null default '',
  arrivee        date,
  buddy          text not null default '',   -- facultatif
  synthese_text  text,
  synthese_at    timestamptz,
  unlocked       text[] not null default '{}',   -- badges déjà annoncés
  is_demo        boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists pds_passports_hotel_idx on public.pds_passports(hotel_id);
create index if not exists pds_passports_owner_idx on public.pds_passports(owner_id);

-- ----------------------------------------------------------- Évaluations ----
-- Une ligne par (passeport, item, évaluateur). Ce découpage évite que deux
-- personnes qui remplissent le même passeport en même temps s'écrasent.
create table if not exists public.pds_evaluations (
  passport_id  uuid not null references public.pds_passports(id) on delete cascade,
  item_key     text not null,                       -- ex. « savoir.s1.0 »
  evaluator    text not null check (evaluator in ('auto', 'buddy', 'coo')),
  level        smallint check (level between 0 and 3),
  note         text not null default '',
  updated_at   timestamptz not null default now(),
  updated_by   uuid,
  primary key (passport_id, item_key, evaluator)
);

-- ================================================================ Aides ====
-- « security definer » : ces fonctions lisent pds_profiles sans repasser par
-- les politiques, ce qui éviterait sinon une récursion infinie.

create or replace function public.pds_role() returns text
language sql stable security definer set search_path = public as $$
  select role from public.pds_profiles
   where id = auth.uid() and status <> 'desactive'
$$;

create or replace function public.pds_hotel() returns uuid
language sql stable security definer set search_path = public as $$
  select hotel_id from public.pds_profiles
   where id = auth.uid() and status <> 'desactive'
$$;

create or replace function public.pds_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.pds_role() = 'admin', false)
$$;

-- Qui voit quel passeport : l'administrateur tout, l'Officer / buddy et le
-- propriétaire ceux de leur hôtel plus la démonstration, le collaborateur
-- les siens.
create or replace function public.pds_can_see(p_passport uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select case public.pds_role()
    when 'admin' then true
    when 'officer' then exists (
      select 1 from public.pds_passports p
       where p.id = p_passport and (p.is_demo or p.hotel_id = public.pds_hotel()))
    when 'proprietaire' then exists (
      select 1 from public.pds_passports p
       where p.id = p_passport and (p.is_demo or p.hotel_id = public.pds_hotel()))
    when 'collaborateur' then exists (
      select 1 from public.pds_passports p
       where p.id = p_passport and p.owner_id = auth.uid())
    else false
  end
$$;

-- Qui remplit quelle colonne : le collaborateur son auto-évaluation,
-- l'Officer / buddy les colonnes buddy et COO, le propriétaire rien,
-- l'administrateur les trois.
create or replace function public.pds_can_write(p_passport uuid, p_evaluator text)
returns boolean
language sql stable security definer set search_path = public as $$
  select case public.pds_role()
    when 'admin' then public.pds_can_see(p_passport)
    when 'officer' then p_evaluator in ('buddy', 'coo') and public.pds_can_see(p_passport)
    when 'collaborateur' then p_evaluator = 'auto' and public.pds_can_see(p_passport)
    else false
  end
$$;

-- ================================================================ RLS ======
alter table public.pds_hotels      enable row level security;
alter table public.pds_profiles    enable row level security;
alter table public.pds_passports   enable row level security;
alter table public.pds_evaluations enable row level security;

-- Hôtels : tout profil actif les lit, l'administrateur seul les gère.
drop policy if exists pds_hotels_read on public.pds_hotels;
create policy pds_hotels_read on public.pds_hotels
  for select using (public.pds_role() is not null);
drop policy if exists pds_hotels_write on public.pds_hotels;
create policy pds_hotels_write on public.pds_hotels
  for all using (public.pds_is_admin()) with check (public.pds_is_admin());

-- Profils : chacun le sien ; l'administrateur tous ; l'Officer / buddy et le
-- propriétaire ceux de leur hôtel, pour afficher les noms.
drop policy if exists pds_profiles_read on public.pds_profiles;
create policy pds_profiles_read on public.pds_profiles
  for select using (
    id = auth.uid()
    or public.pds_is_admin()
    or (public.pds_role() in ('officer', 'proprietaire') and hotel_id = public.pds_hotel())
  );
-- Les comptes sont créés et modifiés par la fonction serveur d'invitation,
-- qui utilise la clé de service et contourne la RLS. Rien côté navigateur.
drop policy if exists pds_profiles_write on public.pds_profiles;
create policy pds_profiles_write on public.pds_profiles
  for all using (public.pds_is_admin()) with check (public.pds_is_admin());

-- Passeports.
drop policy if exists pds_passports_read on public.pds_passports;
create policy pds_passports_read on public.pds_passports
  for select using (public.pds_can_see(id));
drop policy if exists pds_passports_insert on public.pds_passports;
create policy pds_passports_insert on public.pds_passports
  for insert with check (
    public.pds_is_admin()
    or (public.pds_role() = 'officer' and hotel_id = public.pds_hotel())
  );
-- Couverture et synthèse : administrateur et Officer / buddy.
drop policy if exists pds_passports_update on public.pds_passports;
create policy pds_passports_update on public.pds_passports
  for update using (
    public.pds_is_admin()
    or (public.pds_role() = 'officer' and public.pds_can_see(id))
  );
drop policy if exists pds_passports_delete on public.pds_passports;
create policy pds_passports_delete on public.pds_passports
  for delete using (public.pds_is_admin());

-- Évaluations : lecture si le passeport est visible, écriture selon la colonne.
drop policy if exists pds_eval_read on public.pds_evaluations;
create policy pds_eval_read on public.pds_evaluations
  for select using (public.pds_can_see(passport_id));
drop policy if exists pds_eval_insert on public.pds_evaluations;
create policy pds_eval_insert on public.pds_evaluations
  for insert with check (public.pds_can_write(passport_id, evaluator));
drop policy if exists pds_eval_update on public.pds_evaluations;
create policy pds_eval_update on public.pds_evaluations
  for update using (public.pds_can_write(passport_id, evaluator))
          with check (public.pds_can_write(passport_id, evaluator));
drop policy if exists pds_eval_delete on public.pds_evaluations;
create policy pds_eval_delete on public.pds_evaluations
  for delete using (public.pds_is_admin());

-- ========================================================== Horodatage =====
create or replace function public.pds_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists pds_passports_touch on public.pds_passports;
create trigger pds_passports_touch before update on public.pds_passports
  for each row execute function public.pds_touch();

drop trigger if exists pds_evaluations_touch on public.pds_evaluations;
create trigger pds_evaluations_touch before update on public.pds_evaluations
  for each row execute function public.pds_touch();

-- Toute écriture sur une évaluation remonte sur le passeport, pour que la
-- liste « modifié le » reste juste.
create or replace function public.pds_touch_passport() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.pds_passports set updated_at = now()
   where id = coalesce(new.passport_id, old.passport_id);
  return coalesce(new, old);
end $$;

drop trigger if exists pds_eval_touch_passport on public.pds_evaluations;
create trigger pds_eval_touch_passport after insert or update or delete
  on public.pds_evaluations
  for each row execute function public.pds_touch_passport();
