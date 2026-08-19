# Passeport des Savoirs — Oversight

Le fil conducteur de l’intégration de chaque nouveau collaborateur. Faisant référence au
voyage, il retrace son parcours, les compétences acquises, les étapes franchies et les
expériences validées tout au long de son évolution au sein de l’établissement.

**En ligne :** https://teamoversight.github.io/passeport-savoirs/

## Contenu du repo

| Fichier | Rôle |
|---|---|
| `index.html` | Toute l’application. Aucune dépendance à installer. |
| `README.md` | Ce document. |

Fichier autonome (HTML + CSS + JavaScript). Seules ressources externes : les polices Google
Fonts *Inter* et *Playfair Display*.

## Identification et profils

L’accès se fait par **identifiant**, avec un **code d’accès optionnel** défini par
l’administrateur. Quatre profils :

| Profil | Voit | Remplit | Administre |
|---|---|---|---|
| **Collaborateur** | ses passeports uniquement | sa seule colonne d’auto-évaluation | — |
| **Officer / buddy** | les passeports de son hôtel, plus la démonstration | les colonnes buddy et COO | crée des passeports sur son hôtel |
| **Propriétaire** | les passeports de son hôtel | rien — lecture seule | — |
| **Administrateur** | tous les passeports, tous hôtels | les trois colonnes | hôtels, comptes, passeports |

Le collaborateur consulte sa synthèse sans pouvoir la produire ni l’effacer, et sa couverture de
passeport est en lecture seule. L’Officer / buddy crée des passeports sur son hôtel ; seul
l’administrateur supprime, réinitialise et modifie les codes d’accès.

Le **propriétaire** est un profil de consultation : il ouvre les passeports de son hôtel, lit les
trois colonnes, la progression, les badges et **la synthèse d’intégration**, et peut exporter ou
imprimer. Il ne modifie aucun niveau, aucun commentaire, aucune couverture, ne crée ni ne supprime
de passeport, et ne produit pas la synthèse. Contrairement à l’Officer, il n’a **pas** accès au
passeport de démonstration, sauf s’il est lui-même rattaché à l’Hôtel de démonstration.

Créer un passeport crée aussi le **compte du collaborateur**, dont l’identifiant est affiché à
ce moment-là — c’est la seule fois. Sans ce compte, l’intéressé ne pourrait pas s’auto-évaluer.

Le **buddy est facultatif** : un passeport peut n’en avoir aucun.

L’onglet **Administration** permet de créer les hôtels, les Officers, les propriétaires et les
collaborateurs, de les rattacher à un hôtel, et d’attribuer un passeport supplémentaire à un
collaborateur qui change de service. Créer un collaborateur crée en même temps son passeport ;
un Officer et un propriétaire n’en ont pas.

### ⚠️ Ce n’est pas une sécurité

Le site est statique : **tout son code est public** et les données vivent dans le `localStorage`
du navigateur. Le contrôle par profil organise l’interface, il ne protège rien. Quiconque ouvre
les outils de développement voit l’ensemble des comptes et des passeports, quel que soit le
profil connecté. Les codes d’accès sont un garde-fou contre l’erreur, pas un secret.

**N’y saisissez donc aucune information que vous ne pourriez pas rendre publique.**

Pour une vraie séparation des accès, il faut un serveur qui authentifie et qui ne renvoie à
chaque profil que les données auxquelles il a droit. Le modèle de données y est prêt : `HOTELS`,
`USERS`, `RECORDS`, et les fonctions `canSee()` et `allowedRoles()` qui concentrent toutes les
règles de visibilité.

### Comptes d’amorçage

Au premier chargement, quatre comptes de démonstration sont créés, sans code d’accès :

| Identifiant | Profil |
|---|---|
| `admin` | Administrateur — tous les hôtels |
| `officer` | Officer / buddy — Hôtel de démonstration |
| `proprietaire` | Propriétaire — Hôtel de démonstration |
| `camille.durand` | Collaborateur — Hôtel de démonstration |

Ils figurent dans le code source, donc publiquement. **Première chose à faire en production :
créer les comptes réels avec des codes d’accès, puis supprimer ces quatre-là.**

Le compte `proprietaire` est arrivé après les trois autres : sur un navigateur qui avait déjà
ouvert l’outil, il est ajouté une seule fois au chargement (indicateur
`pds.seeded.proprietaire.v1`), et uniquement si les comptes de démonstration sont encore en place
— un compte supprimé volontairement ne reparaît pas.

## Les quatre écrans

1. **Connexion** — identifiant et code d’accès.
2. **Les passeports** (`#/`) — **c’est l’accueil** : la liste des passeports du périmètre du
   profil connecté s’affiche à la connexion, sans clic supplémentaire. Recherche (nom du
   collaborateur, nom du buddy, service, hôtel), filtre par service, progression, badges, date
   de dernière modification. Le bouton « ＋ Nouveau passeport » y figure pour l’administrateur
   et l’Officer / buddy : le service se choisit dans la modale, plus besoin de passer par une
   carte de service.
3. **Comment ça marche** (`#/guide`) — les explications, sorties de l’accueil : le pitch, les 3
   blocs, l’échelle, la règle des badges, les trois regards, et les passeports par service.
   Accessible à tous les profils, collaborateur compris.
4. **Le passeport** (`#/d/<id>`) — la couverture, les 3 blocs, les items, la collection de
   tampons et l’espace synthèse.

L’administrateur dispose d’un cinquième écran, **Administration**.

L’ancienne adresse `#/dossiers` reste valable : elle ouvre la même liste que l’accueil.

## Passeport de démonstration

Au premier chargement, un dossier fictif est posé dans la liste : **Camille Durand**, repérée
par une étiquette « Démo », rattachée à l’Hôtel de démonstration et accessible avec le compte
collaborateur `camille.durand`. Il est entièrement rempli — les 78 items évalués par les trois
regards, 31 items commentés, 12 écarts d’auto-évaluation, les 12 badges, le golden badge et une
synthèse — et sert à montrer le passeport en fin de parcours sans avoir à le remplir soi-même.

Il se supprime comme n’importe quel autre passeport et ne revient pas : un indicateur
(`pds.seeded.v1`) mémorise que l’amorçage a déjà eu lieu. Pour modifier son contenu, voir
`DEMO_NOTES` et `DEMO_SYNTHESE` en fin de script.

## Structure fonctionnelle

- **3 blocs** : Savoir, Savoir-faire, Savoir-être.
- **Sous-blocs** : chacun porte un objectif et un badge.
- **Échelle à quatre niveaux** par item, commune aux trois blocs : ⚪ Non vérifié · 🔴 Non
  acquis · 🟠 En cours d’acquisition · 🟢 Acquis. Le seuil du badge est 🟢, défini par la
  constante `ACQUIS`.
- **3 évaluateurs** par item : le collaborateur (auto-évaluation), le buddy, le COO. Chacun a
  son niveau et son commentaire libre.
- **Une seule colonne modifiable à la fois** : le sélecteur « Je remplis en tant que » ouvre la
  colonne du rôle choisi et verrouille les deux autres (repérées 🔒). Elles restent lisibles —
  le buddy voit l’auto-évaluation du collaborateur, et réciproquement — mais ni les niveaux ni
  les commentaires d’autrui ne peuvent être modifiés par erreur.
- **Badge de sous-bloc** : obtenu lorsque 100 % des items du sous-bloc sont au niveau 🟢.
- **Golden badge 🌟 Ambassadeur de l’hôtel** : obtenu lorsque tous les badges sont acquis.

### Règle du « niveau retenu »

Un item porte trois évaluations. Le niveau qui compte pour la progression et les badges est le
**niveau retenu** : la validation la plus engageante disponible, dans l’ordre
**COO → buddy → auto-évaluation**. L’avis du COO fait foi dès qu’il est renseigné ; à défaut
celui du buddy ; à défaut l’auto-évaluation.

Cette règle tient dans la fonction `retained()` : c’est le seul endroit à modifier pour changer
de politique (exiger la validation du COO, faire une moyenne…).

## Espace synthèse

Chaque passeport dispose d’un espace dédié qui produit une lecture d’ensemble des trois
regards, en trois sections : **où en est l’intégration**, **points forts**, **écarts de
perception** entre auto-évaluation et regards externes. Le brief demande explicitement de s’en
tenir là — ni axes de progression, ni plan d’action, ni verdict sur l’autonomie.

L’Officer / buddy et l’administrateur la produisent ; le collaborateur et le propriétaire la
consultent, sans pouvoir la modifier ni l’effacer.

**Fonctionnement par défaut, sans serveur :**

1. « Copier le brief pour l’IA » assemble le passeport complet — les 3 blocs, chaque item, les
   trois évaluations, tous les commentaires, l’état des badges — et y ajoute la consigne de
   rédaction.
2. On colle dans Claude.
3. On rapatrie la réponse dans l’espace synthèse. Elle est enregistrée dans le dossier du
   collaborateur, rendue en markdown, imprimée avec le passeport et incluse dans l’export JSON.

**Pourquoi pas de génération automatique :** il faudrait une clé d’API dans la page. Le site
étant public, cette clé serait lisible par tous et utilisable à nos frais.

**Pour activer la génération en un clic :** déployer un petit proxy (Cloudflare Worker,
fonction Vercel…) qui garde la clé côté serveur, accepte `POST {prompt:"…"}` et renvoie
`{text:"…"}`, puis renseigner son URL dans la constante `AI_ENDPOINT` en tête du script. Le
bouton bascule alors automatiquement en génération directe.

## Passeports livrés

| Service | État |
|---|---|
| Réceptionniste | Complet — 78 items, 12 badges |
| Housekeeping | À venir — items à définir |
| Maintenance | À venir — items à définir |
| Petit Déjeuner | À venir — items à définir |
| F&B | À venir — items à définir |

Les items des quatre derniers services doivent être définis avec chaque service.

### Ajouter les items d’un service

Dans `index.html`, chercher `const SERVICES`. Le service concerné y est déclaré via
`skeleton(...)`. Le remplacer par un objet bâti sur le modèle de `RECEPTIONNISTE` : pour chaque
bloc, une liste de `subs`, chacun avec `name`, `obj`, `badge` et `items`. Une fois les `subs`
renseignés, la carte passe automatiquement de « Items à définir » à « Disponible » et le
bouton « Nouveau passeport » apparaît.

## Données et partage

Tout est enregistré dans le **`localStorage` du navigateur** : les passeports restent sur le
poste et dans le navigateur où ils ont été saisis. Il n’y a pas de serveur.

- Le collaborateur, le buddy et le COO remplissent le même passeport **sur le même poste**
  (l’entretien d’intégration, par exemple). Le profil connecté détermine les colonnes
  accessibles : un collaborateur n’ouvre que son auto-évaluation, un Officer les trois.
- **Exporter** produit un JSON contenant les trois colonnes, les commentaires, les badges et la
  synthèse : c’est le format d’archivage. Il n’y a pas de réimport dans l’interface — un JSON
  exporté se relit dans un éditeur de texte, ou se réinjecte à la main dans le stockage du
  navigateur si besoin.
- **Imprimer / PDF** produit le passeport complet, commentaires et synthèse inclus, à archiver
  dans le dossier du collaborateur. C’est la sortie à privilégier pour partager un passeport.
- Vider le cache du navigateur efface les données. Exporter ou imprimer régulièrement.

### Passer à un partage temps réel

Pour que les trois personnes travaillent simultanément à distance, il faudrait un backend
(Supabase, Firebase) avec des comptes utilisateurs. Le code est prêt pour cela : toute la
persistance passe par `readJSON`, `writeJSON` et `saveRecords`. Remplacer ces trois fonctions
par des appels réseau suffit, sans toucher à l’interface.

## Charte graphique

| Couleur | Code |
|---|---|
| Blue Flash | `#496BFF` |
| Blue Dark | `#00011E` |
| Kaki | `#7C9182` |
| Blue Light | `#EDF3FF` |
| Grey Light | `#F2F1EE` |
| Kaki Light | `#E3EAE5` |

Polices : **Playfair Display** pour les mots mis en avant dans les titres, **Inter** pour le
reste. Fond : dégradé linéaire 135° `#BFD7FF` → `#F5EDDC` avec effet de grain. L’espace
synthèse utilise l’accent doré `#A78552` pour se distinguer du reste du passeport.

## Publier une mise à jour

Le site est servi par GitHub Pages depuis la branche `main`. Toute modification de `index.html`
poussée sur `main` est en ligne après une ou deux minutes.
