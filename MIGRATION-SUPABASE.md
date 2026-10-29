# Passage à Supabase — notes d'installation

Objectif : que chacun se connecte depuis son propre appareil, avec un accès créé
par l'administrateur, et que tout le monde voie le travail des autres. C'est le
mécanisme déjà en place sur l'Officer Academy.

## Décisions

| Décision | Raison |
| --- | --- |
| Réutiliser le projet Supabase de l'Officer Academy (`zphwgkovpwcxxlsgheex`) | Évite une seconde installation complète — clés, envoi d'e-mails, configuration. Une personne présente dans les deux outils s'y connecte avec le même identifiant. |
| Tables préfixées `pds_` | Rien n'est partagé avec l'Academy en dehors de `auth.users`. Les deux outils restent indépendants. |
| Une ligne par (passeport, item, évaluateur) | Deux personnes qui remplissent le même passeport en même temps ne s'écrasent pas : chacune n'écrit que ses propres lignes. |
| Droits appliqués par la base (RLS) | Contrairement à la version navigateur, ce n'est plus décoratif : même en appelant l'API directement, personne ne voit ce qui ne le regarde pas. |
| Fonction serveur sans dépendance | Le site reste un fichier HTML sans étape de construction ; la fonction d'invitation parle à Supabase en REST. |
| Hébergement Cloudflare Pages | Nécessaire pour la fonction d'invitation, que GitHub Pages ne sait pas exécuter. Remplace le Worker `passeport-savoirs`, qui ne se redéployait pas. |

## Qui peut quoi

| Profil | Voit | Remplit | Invite |
| --- | --- | --- | --- |
| Collaborateur | ses passeports | sa colonne d'auto-évaluation | — |
| Officer / buddy | son hôtel + la démonstration | colonnes buddy et COO | un collaborateur de son hôtel |
| Propriétaire | son hôtel + la démonstration | rien, lecture seule | — |
| Administrateur | tout | les trois colonnes | tout profil, tout hôtel |

## Installation

1. **La base** — ouvrir le projet Supabase, onglet SQL Editor, coller le contenu
   de `supabase/migrations/001_pds_schema.sql` et exécuter. À faire une fois.
2. **L'hébergement** — créer un projet Cloudflare **Pages** connecté au dépôt
   GitHub `teamoversight/passeport-savoirs`. Aucune commande de construction,
   dossier de sortie `/`, branche `main`.
3. **Les variables** — dans les réglages du projet Pages :
   - `SUPABASE_URL` : `https://zphwgkovpwcxxlsgheex.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` : la clé `service_role`, à copier depuis
     Supabase directement dans Cloudflare. Elle ne doit transiter par aucune
     conversation ni être commitée.
   - `SITE_URL` : l'adresse du site une fois connue.
4. **Le premier administrateur** — créé à la main dans Supabase, puis sa ligne
   `pds_profiles` passée en `role = 'admin'`. Les suivants sont invités depuis
   l'interface.

## Reste à faire

- Brancher l'application sur la base : connexion, chargement et écriture.
- Écran « choisir son mot de passe » à l'arrivée depuis l'e-mail d'invitation.
- Reprise du passeport de démonstration.
