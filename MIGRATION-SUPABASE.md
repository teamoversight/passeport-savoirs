# Passage à Supabase — notes d'installation

Objectif : que chacun se connecte depuis son propre appareil, avec un accès créé
par l'administrateur, et que tout le monde voie le travail des autres.

L'**Officer Academy a servi de modèle** pour le mécanisme d'invitation. Elle
n'est en rien modifiée : aucun fichier de son projet n'est touché, et le
Passeport des Savoirs a sa propre base.

## Cloisonnement avec l'Officer Academy

Le Passeport utilise un **projet Supabase qui lui est propre**. Les deux outils
ne partagent donc rien :

| | Officer Academy | Passeport des Savoirs |
| --- | --- | --- |
| Projet Supabase | le sien | le sien |
| Comptes (`auth.users`) | les siens | les siens |
| Sauvegardes et restaurations | indépendantes | indépendantes |
| Clés d'API | les siennes | les siennes |
| Quota d'envoi d'e-mails | le sien | le sien |

Un projet partagé avait été envisagé pour éviter une seconde installation. Il a
été écarté pour trois raisons :

1. La routine d'anonymisation de l'Academy supprime des comptes `auth.users`
   après 24 mois d'inactivité. Une personne présente dans les deux outils aurait
   perdu son accès au Passeport sans que personne ne l'ait décidé.
2. Les sauvegardes Supabase sont par projet : restaurer l'un aurait ramené
   l'autre à la même date.
3. Le Passeport aurait embarqué la clé publique de l'Academy dans sa page, et
   les invitations des deux outils auraient partagé le même quota d'envoi.

Conséquence assumée : une personne présente dans les deux outils a **deux
comptes distincts**, avec deux mots de passe. C'est le prix de l'isolation.

## Décisions

| Décision | Raison |
| --- | --- |
| Projet Supabase dédié | Aucun impact possible sur l'Officer Academy. |
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

## Le projet, tel qu'installé

| | |
| --- | --- |
| Projet Supabase | `passeport-savoirs`, organisation Oversight |
| Référence | `otynyiemlwbbbnbooktc` |
| URL | `https://otynyiemlwbbbnbooktc.supabase.co` |
| Région | eu-west-1, Irlande |
| Clé publique | `sb_publishable_V-Cd_bR87wDiys4Qv1NXfg_Kw-D0IRx` |

La clé publique part dans le navigateur de chaque visiteur : elle figure dans la
page, c'est sa raison d'être. Ce qu'elle autorise est entièrement déterminé par
les politiques RLS.

Ce projet utilise le **nouveau format de clés Supabase** (`sb_publishable_…` et
`sb_secret_…`), là où l'Officer Academy utilisait l'ancien (jetons JWT `anon` et
`service_role`). La variable `SUPABASE_SERVICE_ROLE_KEY` contiendra donc une clé
`sb_secret_…` ; elle se présente dans les mêmes en-têtes et la fonction
d'invitation n'a pas besoin d'être modifiée.

## Vérifié le 29 octobre 2026

Script exécuté dans le projet dédié, résultat « Success. No rows returned ».

| Table | RLS | Politiques | Colonnes |
| --- | --- | --- | --- |
| `pds_evaluations` | active | 4 | 7 |
| `pds_hotels` | active | 2 | 3 |
| `pds_passports` | active | 4 | 13 |
| `pds_profiles` | active | 2 | 9 |

Contrôle depuis un navigateur non authentifié, avec la clé publique :

- lecture des quatre tables : `200` et une liste vide, rien n'est exposé ;
- tentative d'écriture : `401 — new row violates row-level security policy`.

## Installation

1. ~~**Créer un projet Supabase**~~ — fait.
2. ~~**Installer la base**~~ — fait, et vérifié.
3. ~~**Configurer l'envoi d'e-mails**~~ — fait, et testé par un envoi réel.

   | Champ | Valeur |
   | --- | --- |
   | Serveur | `smtp.gmail.com`, port 465 |
   | Identifiant | `team@hoteloversight.com` |
   | Mot de passe | mot de passe d'application Google, 16 lettres |
   | Expéditeur | `team@hoteloversight.com`, affiché « Passeport des Savoirs » |

   **Si une invitation échoue avec `500 — Error sending invite email`**, la cause
   est presque toujours là. Le détail se lit dans *Logs → Auth Logs*, champ
   `error`. Un `535 BadCredentials` signifie que Gmail refuse le mot de passe :
   il faut un **mot de passe d'application**, pas le mot de passe habituel du
   compte, et il doit appartenir au compte `team@hoteloversight.com`. C'est
   exactement ce qui est arrivé au premier essai.

   Le bandeau orange de Supabase sur Gmail est attendu et sans conséquence à ce
   volume. La limite d'envoi passe à 30 e-mails par heure.
4. ~~**Créer le projet Cloudflare Pages**~~ — fait.

   Projet **Pages** `passeport-savoirs`, connecté à `teamoversight/passeport-savoirs`,
   branche `main`, déploiements automatiques activés. Aucun préréglage de
   framework, aucune commande de construction, sortie à la racine.

   Adresse : **https://passeport-savoirs.pages.dev**

   L'ancien **Worker** du même nom subsiste et sert une version périmée sous
   `passeport-savoirs.hoteloversight.workers.dev`. Il n'a jamais redéployé depuis
   Git. À supprimer une fois le nouveau site validé, pour éviter deux adresses
   qui ne montrent pas la même chose.
5. ~~**Renseigner les variables**~~ — fait. Pour mémoire :
   - `SUPABASE_URL` : `https://otynyiemlwbbbnbooktc.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` : la clé **secrète** (`sb_secret_…`), copiée de
     Supabase directement dans Cloudflare. Elle ne transite par aucune conversation et
     n'entre jamais dans le dépôt.
   - `SITE_URL` : l'adresse du site une fois connue.
6. ~~**Créer le premier administrateur**~~ — fait.

   `elina.michel@hoteloversight.com` a été invitée depuis *Authentication →
   Users → Add user → Send invitation*, puis sa ligne `pds_profiles` créée avec
   `role = 'admin'`. Son statut restera `invite` jusqu'à ce qu'elle choisisse son
   mot de passe depuis l'e-mail reçu — ce qui suppose que l'application soit
   branchée et déployée. Les administrateurs suivants s'inviteront depuis
   l'interface, sans repasser par le SQL.

## Reste à faire

- Brancher l'application sur la base : connexion, chargement et écriture.
- Écran « choisir son mot de passe » à l'arrivée depuis l'e-mail d'invitation.
- Reprise du passeport de démonstration.
