# Passeport des Savoirs — Oversight

Le fil conducteur de l’intégration de chaque nouveau collaborateur. Faisant référence au
voyage, il retrace son parcours, les compétences acquises, les étapes franchies et les
expériences validées tout au long de son évolution au sein de l’établissement.

**En ligne :** https://teamoversight.github.io/passeport-savoirs/

## Contenu du repo

| Fichier | Rôle |
|---|---|
| `index.html` | Toute l’application : landing page, passeports, créateur de passeport. Aucune dépendance à installer. |
| `README.md` | Ce document. |

Le fichier est autonome (HTML + CSS + JavaScript dans un seul fichier). Les seules
ressources externes sont les polices Google Fonts *Inter* et *Playfair Display*.

## Structure fonctionnelle

- **3 blocs** : Savoir, Savoir-faire, Savoir-être.
- **Sous-blocs** : chacun porte un objectif et un badge.
- **Échelle à 3 niveaux** par item : ⚪ niveau 0, 🟡 niveau 1, 🟢 niveau 2.
  Les intitulés du niveau 2 diffèrent selon le bloc (expliquer / mettre en pratique en
  autonomie / être observé régulièrement).
- **3 évaluateurs** par item : le collaborateur (auto-évaluation), le buddy, le COO.
  Chacun dispose de son propre niveau et de son propre commentaire libre.
- **Badge de sous-bloc** : obtenu lorsque 100 % des items du sous-bloc sont au niveau 🟢.
  Il s’affiche en pop-up.
- **Golden badge 🌟 Ambassadeur de l’hôtel** : obtenu lorsque tous les badges du passeport
  sont acquis.

### Règle du « niveau retenu »

Un item porte trois évaluations. Le niveau qui compte pour la progression et les badges est
le **niveau retenu** : la validation la plus engageante disponible, dans cet ordre
**COO → buddy → auto-évaluation**. Autrement dit, l’avis du COO fait foi dès qu’il est
renseigné ; à défaut, celui du buddy ; à défaut, l’auto-évaluation.

Cette règle est isolée dans la fonction `retained()` du fichier `index.html` : c’est le seul
endroit à modifier pour changer de politique (par exemple exiger la validation du COO, ou
faire une moyenne).

## Passeports livrés

| Service | État |
|---|---|
| Réceptionniste | Complet — 78 items, 12 badges |
| Housekeeping | Structure et échelles prêtes, items à définir |
| Maintenance | Structure et échelles prêtes, items à définir |
| Petit Déjeuner | Structure et échelles prêtes, items à définir |
| F&B | Structure et échelles prêtes, items à définir |

Les items des quatre derniers services n’ont pas été inventés : ils doivent être définis avec
chaque service. La carte « À construire » ouvre directement le créateur de passeport,
pré-rempli avec le nom du service, les 3 blocs et les échelles. Le passeport créé remplace
alors la carte « À construire ».

## Créer ou modifier un passeport

Deux voies :

1. **Depuis l’interface** — bouton « Créer un passeport ». On saisit le service, puis les
   sous-blocs (nom, objectif, badge, items un par ligne). Le passeport est enregistré dans le
   navigateur et apparaît sur la page d’accueil. Il peut ensuite être exporté en JSON.
2. **Dans le code** — pour un passeport officiel destiné à tous les hôtels, mieux vaut
   l’ajouter dans `index.html` : recopier le bloc `const RECEPTIONNISTE = {...}` sous un
   nouveau nom, puis l’ajouter à la liste `BUILTIN`. Il est alors versionné dans git et servi
   à tout le monde, sans dépendre du navigateur de chacun.

Le JSON exporté depuis le créateur contient la définition complète (clé `definition`) et peut
servir de base à cette recopie.

## Données et partage

Les évaluations sont enregistrées dans le **`localStorage` du navigateur** : elles restent sur
le poste et dans le navigateur où elles ont été saisies. Il n’y a pas de serveur.

Conséquences pratiques :

- Le collaborateur, le buddy et le COO peuvent remplir le même passeport **sur le même poste**
  (l’entretien d’intégration, par exemple) — chacun a sa colonne.
- Pour un remplissage **à distance**, il faut passer par **Exporter** / **Importer** : le
  fichier JSON contient les trois colonnes, les commentaires et les badges.
- **Imprimer / PDF** produit une version papier complète, commentaires inclus, à archiver
  dans le dossier du collaborateur.
- Vider le cache du navigateur efface les données. Exporter régulièrement.

### Passer à un partage temps réel

Pour que les trois personnes travaillent simultanément à distance, il faudrait un backend
(Supabase ou Firebase) avec des comptes utilisateurs. Le code est organisé pour cela : toute
la persistance passe par `readJSON` / `writeJSON` / `saveState`. Remplacer ces trois fonctions
par des appels réseau suffit, sans toucher à l’interface.

## Charte graphique

Conforme à la charte Oversight :

| Couleur | Code |
|---|---|
| Blue Flash | `#496BFF` |
| Blue Dark | `#00011E` |
| Kaki | `#7C9182` |
| Blue Light | `#EDF3FF` |
| Grey Light | `#F2F1EE` |
| Kaki Light | `#E3EAE5` |

Polices : **Playfair Display** pour les mots mis en avant dans les titres, **Inter** pour le
reste. Fond : dégradé linéaire 135° `#BFD7FF` → `#F5EDDC` avec effet de grain.

## Publier une mise à jour

Le site est servi par GitHub Pages depuis la branche `main`. Toute modification de
`index.html` poussée sur `main` est en ligne après une ou deux minutes.
