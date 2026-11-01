-- =============================================================================
-- Migration 00001 — Extensions et fonctions utilitaires
-- -----------------------------------------------------------------------------
-- Extensions PostgreSQL disponibles sur Neon, Supabase et Cloud SQL :
--   * citext   : type texte insensible à la casse (e-mails : A@b.fr = a@B.fr)
--   * unaccent : suppression des accents (« Plélan » trouvé avec « plelan »)
--   * pg_trgm  : recherche par similarité (tolère les fautes de frappe) et
--                index accélérant les recherches « contient » (ILIKE '%…%')
-- gen_random_uuid() est natif depuis PostgreSQL 13 (aucune extension requise).
-- =============================================================================

-- +goose Up
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- -----------------------------------------------------------------------------
-- search_normalize(text) : minuscules + sans accents.
-- unaccent() n'est pas déclarée IMMUTABLE par PostgreSQL (son dictionnaire
-- pourrait changer), ce qui interdit de l'utiliser dans un index. On l'enveloppe
-- dans une fonction IMMUTABLE en fixant explicitement le dictionnaire : c'est la
-- pratique recommandée. Toute recherche texte DOIT passer par cette fonction
-- pour bénéficier des index trigrammes.
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
CREATE FUNCTION search_normalize(input text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
STRICT
AS $$
    SELECT lower(public.unaccent('public.unaccent'::regdictionary, input));
$$;
-- +goose StatementEnd

COMMENT ON FUNCTION search_normalize(text) IS
    'Normalise un texte pour la recherche : minuscules, sans accents. IMMUTABLE pour être indexable.';

-- -----------------------------------------------------------------------------
-- set_updated_at() : déclencheur qui met à jour la colonne updated_at
-- à chaque modification d'une ligne. Évite d'oublier de le faire dans le code.
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
CREATE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
-- +goose StatementEnd

COMMENT ON FUNCTION set_updated_at() IS
    'Déclencheur BEFORE UPDATE : renseigne updated_at avec l''horodatage courant.';

-- +goose Down
DROP FUNCTION IF EXISTS set_updated_at();
DROP FUNCTION IF EXISTS search_normalize(text);
DROP EXTENSION IF EXISTS pg_trgm;
DROP EXTENSION IF EXISTS unaccent;
DROP EXTENSION IF EXISTS citext;
