-- =============================================================================
-- Migration 00004 — Médias, organisateurs et lieux
-- =============================================================================

-- +goose Up

-- -----------------------------------------------------------------------------
-- Médias (affiches, logos)
-- Les fichiers sont dans Cloud Storage ; la base ne stocke que leurs
-- métadonnées et leurs clés de stockage. Deux variantes sont générées à
-- l'upload : vignette (400 px) et grande taille (1200 px).
-- is_public = false tant qu'un média joint à une proposition n'est pas validé.
-- -----------------------------------------------------------------------------
CREATE TABLE media (
    id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    kind              text        NOT NULL CHECK (kind IN ('poster', 'logo')),
    thumb_storage_key text        NOT NULL UNIQUE,
    large_storage_key text        NOT NULL UNIQUE,
    mime_type         text        NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
    width             integer     NOT NULL CHECK (width  > 0),
    height            integer     NOT NULL CHECK (height > 0),
    size_bytes        integer     NOT NULL CHECK (size_bytes > 0),
    is_public         boolean     NOT NULL DEFAULT false,
    uploaded_by       uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE media IS 'Métadonnées des images stockées dans Cloud Storage.';
COMMENT ON COLUMN media.thumb_storage_key IS 'Chemin de l''objet vignette dans le bucket (nom aléatoire).';

-- -----------------------------------------------------------------------------
-- Organisateurs (clubs, associations, comités des fêtes, …)
-- -----------------------------------------------------------------------------
CREATE TABLE organizers (
    id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name           text        NOT NULL CHECK (length(name) BETWEEN 2 AND 150),
    type_code      text        NOT NULL DEFAULT 'club' REFERENCES organizer_types (code),
    description    text        CHECK (length(description) <= 5000),
    city_insee     text        REFERENCES cities (insee_code),
    logo_media_id  uuid        REFERENCES media (id) ON DELETE SET NULL,
    email          citext      CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    phone          text        CHECK (phone ~ '^\+?[0-9 .()-]{6,20}$'),
    website_url    text        CHECK (website_url   ~ '^https?://'),
    facebook_url   text        CHECK (facebook_url  ~ '^https?://'),
    instagram_url  text        CHECK (instagram_url ~ '^https?://'),
    created_by     uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE organizers IS 'Organisateurs de tournois (pas uniquement des clubs : RG-13).';

-- Deux organisateurs ne peuvent pas porter le même nom dans la même commune
-- (comparaison insensible à la casse et aux accents) : limite les doublons.
CREATE UNIQUE INDEX organizers_name_city_unique_idx
    ON organizers (search_normalize(name), COALESCE(city_insee, ''));
CREATE INDEX organizers_city_insee_idx  ON organizers (city_insee);
CREATE INDEX organizers_name_search_idx ON organizers USING gin (search_normalize(name) gin_trgm_ops);

CREATE TRIGGER organizers_set_updated_at
    BEFORE UPDATE ON organizers
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Membres d'un organisateur (V2 : espace organisateur)
-- Créée dès maintenant pour que le modèle de droits soit complet ; vide au MVP.
-- -----------------------------------------------------------------------------
CREATE TABLE organizer_members (
    organizer_id uuid        NOT NULL REFERENCES organizers (id) ON DELETE CASCADE,
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (organizer_id, user_id)
);
COMMENT ON TABLE organizer_members IS 'V2 — utilisateurs habilités à gérer un organisateur.';

CREATE INDEX organizer_members_user_id_idx ON organizer_members (user_id);

-- -----------------------------------------------------------------------------
-- Lieux (gymnase, plage, complexe…)
-- Réutilisables d'une édition à l'autre. Les coordonnées viennent de l'API
-- Adresse à la saisie (RG-14) ; elles serviront au filtre de distance (V2).
-- -----------------------------------------------------------------------------
CREATE TABLE venues (
    id            uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    name          text          CHECK (length(name) <= 150),
    address_line  text          CHECK (length(address_line) <= 250),
    postal_code   text          CHECK (postal_code ~ '^[0-9]{5}$'),
    city_insee    text          NOT NULL REFERENCES cities (insee_code),
    latitude      numeric(8, 6) NOT NULL CHECK (latitude  BETWEEN -90  AND 90),
    longitude     numeric(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    geocoding_source text       NOT NULL DEFAULT 'ban'
                                CHECK (geocoding_source IN ('ban', 'city_center', 'manual')),
    created_at    timestamptz   NOT NULL DEFAULT now(),
    updated_at    timestamptz   NOT NULL DEFAULT now()
);
COMMENT ON TABLE venues IS 'Lieux physiques des tournois, géocodés.';
COMMENT ON COLUMN venues.geocoding_source IS 'ban = adresse précise (API Adresse) ; city_center = centre de la commune ; manual = saisie manuelle.';

CREATE INDEX venues_city_insee_idx ON venues (city_insee);

CREATE TRIGGER venues_set_updated_at
    BEFORE UPDATE ON venues
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE IF EXISTS venues;
DROP TABLE IF EXISTS organizer_members;
DROP TABLE IF EXISTS organizers;
DROP TABLE IF EXISTS media;
