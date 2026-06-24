-- ═══════════════════════════════════════════════════════════════
-- GRH MINISTÈRE — Schéma Supabase
-- Coller intégralement dans : Supabase > SQL Editor > New Query
-- ═══════════════════════════════════════════════════════════════

-- ── Extensions ────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── Table des profils utilisateurs ────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nom         text,
  prenom      text,
  email       text,
  role        text not null default 'consultant'
                check (role in ('admin','gestionnaire','chef_service')),
  direction   text,          -- pour chef_service : sa direction uniquement
  actif       boolean default true,
  created_at  timestamptz default now()
);

-- Trigger : créer un profil vide à chaque inscription
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, nom, role)
  values (new.id, new.email, split_part(new.email,'@',1), 'gestionnaire');
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── Table agents ──────────────────────────────────────────────
create table if not exists public.agents (
  id                    bigserial primary key,
  matricule             text unique not null,
  nom                   text not null,
  prenom                text not null,
  date_naissance        date,
  lieu_naissance        text,
  sexe                  text,
  situation_matrimoniale text,
  nb_enfants            int default 0,
  direction             text,
  poste                 text,
  corps                 text,
  categorie             text,
  echelon               text,
  lieu_affectation      text default 'Lomé',
  type_contrat          text,
  date_prise_service    date,
  date_fin_contrat      date,
  statut                text default 'En activité',
  cni                   text,
  tel                   text,
  email                 text,
  diplome               text,
  specialite            text,
  observations          text,
  created_at            timestamptz default now(),
  updated_at            timestamptz default now()
);

-- ── Table congés ──────────────────────────────────────────────
create table if not exists public.conges (
  id                      bigserial primary key,
  agent_id                bigint references public.agents(id) on delete cascade,
  type_conge              text,
  date_depart             date,
  date_retour_prevu       date,
  date_reprise_effective  date,
  interimaire             text,
  jours_demandes          int default 0,
  jours_accordes          int default 0,
  statut                  text default 'En attente',
  visa_responsable        text,
  observations            text,
  created_at              timestamptz default now()
);

-- ── Table permissions ─────────────────────────────────────────
create table if not exists public.permissions (
  id              bigserial primary key,
  agent_id        bigint references public.agents(id) on delete cascade,
  motif           text,
  date_debut      date,
  date_fin        date,
  jours_accordes  int default 0,
  statut          text default 'En attente',
  observations    text,
  created_at      timestamptz default now()
);

-- ── Table absences ────────────────────────────────────────────
create table if not exists public.absences (
  id             bigserial primary key,
  agent_id       bigint references public.agents(id) on delete cascade,
  type_absence   text,
  date_absence   date,
  heure_arrivee  text,
  nb_jours       int default 1,
  statut         text default 'En traitement',
  observations   text,
  created_at     timestamptz default now()
);

-- ── Table documents ───────────────────────────────────────────
create table if not exists public.documents (
  id           bigserial primary key,
  agent_id     bigint references public.agents(id) on delete cascade,
  type_doc     text,
  reference    text,
  date_doc     date,
  fichier_url  text,
  observations text,
  created_at   timestamptz default now()
);

-- ── Table paramètres ──────────────────────────────────────────
create table if not exists public.parametres (
  k    text primary key,
  v    text,
  updated_at timestamptz default now()
);

-- Valeurs par défaut
insert into public.parametres (k,v) values
  ('ministere','MINISTÈRE'),
  ('exercice', extract(year from now())::text),
  ('drh','Le Directeur des Ressources Humaines'),
  ('adresse','Lomé, Togo'),
  ('droits', '[{"t":"Fonctionnaire","de":0,"a":99,"j":30,"cum":60,"base":"Art.196 Statut GFP"},{"t":"Contractuel","de":0,"a":99,"j":30,"cum":60,"base":"Art.196 Statut GFP"},{"t":"Stagiaire","de":0,"a":99,"j":0,"cum":0,"base":"Pas de congé légal"}]'),
  ('perms_legales', '{"Mariage de l''agent":{"j":5,"just":"Acte de mariage"},"Décès conjoint / enfant":{"j":8,"just":"Acte de décès"},"Décès père / mère":{"j":8,"just":"Acte de décès"},"Naissance enfant (père)":{"j":3,"just":"Déclaration naissance"},"Congé maternité":{"j":98,"just":"Certificat médical"},"Congé maladie":{"j":90,"just":"Certificat médical"}}')
on conflict (k) do nothing;

-- ── updated_at automatique ────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
create trigger trg_agents_upd before update on public.agents
  for each row execute procedure public.set_updated_at();

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════
alter table public.profiles   enable row level security;
alter table public.agents     enable row level security;
alter table public.conges     enable row level security;
alter table public.permissions enable row level security;
alter table public.absences   enable row level security;
alter table public.documents  enable row level security;
alter table public.parametres enable row level security;

-- Helper : rôle de l'utilisateur connecté
create or replace function public.my_role()
returns text language sql security definer stable as $$
  select role from public.profiles where id = auth.uid();
$$;

-- Helper : direction de l'utilisateur connecté
create or replace function public.my_direction()
returns text language sql security definer stable as $$
  select direction from public.profiles where id = auth.uid();
$$;

-- ── Profiles ──────────────────────────────────────────────────
create policy "profiles_select" on public.profiles for select
  using (id = auth.uid() or public.my_role() = 'admin');
create policy "profiles_update_self" on public.profiles for update
  using (id = auth.uid());
create policy "profiles_admin" on public.profiles for all
  using (public.my_role() = 'admin');

-- ── Agents ────────────────────────────────────────────────────
-- Admin & Gestionnaire : accès total
-- Chef de service : uniquement sa direction
create policy "agents_read" on public.agents for select using (
  public.my_role() in ('admin','gestionnaire')
  or (public.my_role() = 'chef_service' and direction = public.my_direction())
);
create policy "agents_write" on public.agents for insert with check (
  public.my_role() in ('admin','gestionnaire')
);
create policy "agents_update" on public.agents for update using (
  public.my_role() in ('admin','gestionnaire')
);
create policy "agents_delete" on public.agents for delete using (
  public.my_role() = 'admin'
);

-- ── Congés ────────────────────────────────────────────────────
create policy "conges_read" on public.conges for select using (
  public.my_role() in ('admin','gestionnaire')
  or (public.my_role() = 'chef_service' and
      agent_id in (select id from public.agents where direction = public.my_direction()))
);
create policy "conges_write" on public.conges for insert with check (
  public.my_role() in ('admin','gestionnaire')
);
create policy "conges_update" on public.conges for update using (
  public.my_role() in ('admin','gestionnaire')
);
create policy "conges_delete" on public.conges for delete using (
  public.my_role() = 'admin'
);

-- ── Permissions ───────────────────────────────────────────────
create policy "permissions_read" on public.permissions for select using (
  public.my_role() in ('admin','gestionnaire')
  or (public.my_role() = 'chef_service' and
      agent_id in (select id from public.agents where direction = public.my_direction()))
);
create policy "permissions_write" on public.permissions for insert with check (
  public.my_role() in ('admin','gestionnaire')
);
create policy "permissions_update" on public.permissions for update using (
  public.my_role() in ('admin','gestionnaire')
);
create policy "permissions_delete" on public.permissions for delete using (
  public.my_role() = 'admin'
);

-- ── Absences ──────────────────────────────────────────────────
create policy "absences_read" on public.absences for select using (
  public.my_role() in ('admin','gestionnaire')
  or (public.my_role() = 'chef_service' and
      agent_id in (select id from public.agents where direction = public.my_direction()))
);
create policy "absences_write" on public.absences for insert with check (
  public.my_role() in ('admin','gestionnaire')
);
create policy "absences_update" on public.absences for update using (
  public.my_role() in ('admin','gestionnaire')
);
create policy "absences_delete" on public.absences for delete using (
  public.my_role() = 'admin'
);

-- ── Documents ─────────────────────────────────────────────────
create policy "documents_read" on public.documents for select using (
  public.my_role() in ('admin','gestionnaire')
  or (public.my_role() = 'chef_service' and
      agent_id in (select id from public.agents where direction = public.my_direction()))
);
create policy "documents_write" on public.documents for insert with check (
  public.my_role() in ('admin','gestionnaire')
);
create policy "documents_delete" on public.documents for delete using (
  public.my_role() = 'admin'
);

-- ── Paramètres (admin seulement en écriture) ──────────────────
create policy "params_read" on public.parametres for select using (auth.uid() is not null);
create policy "params_write" on public.parametres for all using (public.my_role() = 'admin');
