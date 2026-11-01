# Base de données

Schéma PostgreSQL de l'application, versionné par migrations [goose](https://github.com/pressly/goose).

| Dossier | Contenu |
|---|---|
| `migrations/` | Migrations SQL numérotées (une section `Up`, une section `Down`). **Ne jamais modifier une migration déjà appliquée en production** : en créer une nouvelle. |
| `seeds/dev_seed.sql` | Données **fictives** de développement (rejouable). Jamais en production. |

Conception détaillée : [docs/03-modele-donnees.md](../../docs/03-modele-donnees.md).

## Essayer en local (Windows, macOS ou Linux)

Prérequis : [Docker Desktop](https://www.docker.com/products/docker-desktop/) et [Go](https://go.dev/dl/).
L'environnement de développement complet (fichier `docker-compose.yml`, `Makefile`) sera fourni au début de la phase 3.

1. Démarrer un PostgreSQL jetable :

```bash
docker run --name volley-db -e POSTGRES_PASSWORD=dev -e POSTGRES_DB=volley -p 5432:5432 -d postgres:17
```

2. Installer goose :

```bash
go install github.com/pressly/goose/v3/cmd/goose@latest
```

3. Appliquer les migrations (depuis le dossier `backend/`) :

```bash
goose -dir db/migrations postgres "postgres://postgres:dev@localhost:5432/volley?sslmode=disable" up
```

4. Charger les données de test :

```bash
docker exec -i volley-db psql -U postgres -d volley < db/seeds/dev_seed.sql
```

5. Explorer la base :

```bash
docker exec -it volley-db psql -U postgres -d volley
```

Exemples dans `psql` : `\dt` (liste des tables), `\d tournaments` (structure d'une table), `SELECT name, start_date FROM tournaments;`.

## Commandes goose utiles

| Commande | Effet |
|---|---|
| `goose … status` | État des migrations |
| `goose … up` | Applique les migrations en attente |
| `goose … down` | Annule la dernière migration |
| `goose … reset` | Annule toutes les migrations |
| `goose -dir db/migrations create nom_migration sql` | Crée une nouvelle migration |

## Note Supabase

Sur Supabase, les extensions sont installées dans le schéma `extensions` et non `public`. Si Supabase est retenu à la place de Neon, la fonction `search_normalize()` (migration 00001) devra référencer `extensions.unaccent`.
