-- ============================================================================
-- Activation d'un compte par son titulaire
--
-- À l'arrivée depuis l'e-mail d'invitation, la personne choisit son mot de
-- passe. Son profil doit alors passer de « invite » à « actif ».
--
-- Elle ne peut pas écrire elle-même dans pds_profiles : la politique réserve
-- cette table à l'administrateur, et c'est volontaire — sans quoi chacun
-- pourrait se changer de rôle ou d'hôtel. Cette fonction fait donc le strict
-- nécessaire, pour la personne connectée et pour elle seule.
-- ============================================================================

create or replace function public.pds_activate_me() returns void
language sql security definer set search_path = public as $$
  update public.pds_profiles
     set status = case when status = 'invite' then 'actif' else status end,
         activated_at = coalesce(activated_at, now())
   where id = auth.uid()
     and status <> 'desactive';
$$;

revoke all on function public.pds_activate_me() from public, anon;
grant execute on function public.pds_activate_me() to authenticated;
