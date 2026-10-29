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

## Installation

1. **Créer un projet Supabase** nommé par exemple `passeport-savoirs`, dans la
   même région que l'Academy (UE).
2. **Installer la base** — SQL Editor, coller le contenu de
   `supabase/migrations/001_pds_schema.sql`, exécuter. À faire une fois.
3. **Configurer l'envoi d'e-mails** — sans cela les invitations ne partent pas.
   Le compte Resend de l'Academy et son domaine vérifié se réutilisent : il
   suffit de reprendre la même clé dans les réglages SMTP du nouveau projet.
4. **Créer le projet Cloudflare Pages** connecté au dépôt
   `teamoversight/passeport-savoirs`. Aucune commande de construction, dossier
   de sortie `/`, branche `main`.
5. **Renseigner les variables** dans les réglages du projet Pages :
   - `SUPABASE_URL` : l'adresse du **nouveau** projet
   - `SUPABASE_SERVICE_ROLE_KEY` : sa clé `service_role`, copiée de Supabase
     directement dans Cloudflare. Elle ne transite par aucune conversation et
     n'entre jamais dans le dépôt.
   - `SITE_URL` : l'adresse du site une fois connue.
6. **Créer le premier administrateur** à la main dans Supabase, puis passer sa
   ligne `pds_profiles` en `role = 'admin'`. Les suivants sont invités depuis
   l'interface.

## Reste à faire

- Brancher l'application sur la base : connexion, chargement et écriture.
- Écran « choisir son mot de passe » à l'arrivée depuis l'e-mail d'invitation.
- Reprise du passeport de démonstration.
