-- =============================================================================
-- Migration 00005 — Séries, éditions (tournois), tableaux et badges
-- -----------------------------------------------------------------------------
-- Modèle (règles RG-01 et RG-02 du cahier des charges) :
--
--   organizers 1──N tournament_series 1──N tournaments 1──N tournament_divisions
--   (organisateur)  (tournoi récurrent)    (édition datée)  (tableaux : 2x2 mixte…)
--
-- « Un tournoi » dans l'application = une ligne de la table tournaments
-- (une édition). Un tournoi ponctuel est une série à une seule édition.
--
-- Trois statuts indépendants coexistent sur une édition :
--   publication_status   : visibilité dans l'app (brouillon → publié…)   RG-03
--   event_status         : déroulement (prévu / reporté / annulé)          RG-04
--   registration_status  : inscriptions (ouvertes / complet…)              RG-05
-- =============================================================================

-- +goose Up

-- -----------------------------------------------------------------------------
-- Séries (tournois récurrents)
-- -----------------------------------------------------------------------------
CREATE TABLE tournament_series (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organizer_id  uuid        NOT NULL REFERENCES organizers (id) ON DELETE RESTRICT,
    name          text        NOT NULL CHECK (length(name) BETWEEN 2 AND 150),
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE tournament_series IS 'Tournoi récurrent (ex. « Tournoi de la Plage de Carnac »), regroupe ses éditions annuelles.';

CREATE INDEX tournament_series_organizer_id_idx ON tournament_series (organizer_id);

CREATE TRIGGER tournament_series_set_updated_at
    BEFORE UPDATE ON tournament_series
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Éditions (= tournois tels que vus par les utilisateurs)
-- -----------------------------------------------------------------------------
CREATE TABLE tournaments (
    id                        uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    series_id                 uuid        NOT NULL REFERENCES tournament_series (id) ON DELETE RESTRICT,
    name                      text        NOT NULL CHECK (length(name) BETWEEN 2 AND 150),
    venue_id                  uuid        NOT NULL REFERENCES venues (id) ON DELETE RESTRICT,

    -- Dates : type date (heure locale française), pas d'horodatage.
    start_date                date        NOT NULL,
    end_date                  date        NOT NULL,
    start_time                time,

    poster_media_id           uuid        REFERENCES media (id) ON DELETE SET NULL,
    description               text        CHECK (length(description) <= 10000),
    rules_text                text        CHECK (length(rules_text)  <= 20000),
    rules_url                 text        CHECK (rules_url ~ '^https?://'),

    -- Inscription (RG-05)
    registration_mode         text        NOT NULL
                                          CHECK (registration_mode IN ('external_link', 'on_site', 'phone_or_email')),
    registration_url          text        CHECK (registration_url ~ '^https?://' AND length(registration_url) <= 2000),
    registration_instructions text        CHECK (length(registration_instructions) <= 500),
    registration_deadline     date,
    registration_status       text        NOT NULL DEFAULT 'not_open_yet'
                                          CHECK (registration_status IN ('not_open_yet', 'open', 'full', 'closed')),

    -- Déroulement (RG-04)
    event_status              text        NOT NULL DEFAULT 'scheduled'
                                          CHECK (event_status IN ('scheduled', 'postponed', 'cancelled')),
    postponed_to_date         date,

    -- Publication (RG-03)
    publication_status        text        NOT NULL DEFAULT 'draft'
                                          CHECK (publication_status IN ('draft', 'pending', 'published', 'rejected', 'archived')),
    rejection_reason          text        CHECK (length(rejection_reason) <= 1000),
    published_at              timestamptz,

    -- Contacts affichés sur la fiche
    contact_email             citext      CHECK (contact_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    contact_phone             text        CHECK (contact_phone ~ '^\+?[0-9 .()-]{6,20}$'),
    contact_url               text        CHECK (contact_url ~ '^https?://'),

    -- Fiabilité (RG-07) et traçabilité
    verified_at               timestamptz NOT NULL DEFAULT now(),
    source_note               text        CHECK (length(source_note) <= 1000),
    created_by                uuid        REFERENCES users (id) ON DELETE SET NULL,
    updated_by                uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at                timestamptz NOT NULL DEFAULT now(),
    updated_at                timestamptz NOT NULL DEFAULT now(),

    -- ---- Contraintes d'intégrité métier ------------------------------------
    CONSTRAINT tournaments_dates_order_chk
        CHECK (end_date >= start_date),
    CONSTRAINT tournaments_external_link_requires_url_chk
        CHECK (registration_mode <> 'external_link' OR registration_url IS NOT NULL),
    CONSTRAINT tournaments_deadline_before_end_chk
        CHECK (registration_deadline IS NULL OR registration_deadline <= end_date),
    CONSTRAINT tournaments_postponed_date_only_if_postponed_chk
        CHECK (postponed_to_date IS NULL OR event_status = 'postponed'),
    CONSTRAINT tournaments_rejected_requires_reason_chk
        CHECK (publication_status <> 'rejected' OR rejection_reason IS NOT NULL),
    CONSTRAINT tournaments_published_requires_date_chk
        CHECK (publication_status NOT IN ('published', 'archived') OR published_at IS NOT NULL)
);
COMMENT ON TABLE tournaments IS 'Éditions datées des tournois. Visibles dans l''app si publication_status = published.';
COMMENT ON COLUMN tournaments.registration_instructions IS 'Consigne si pas de lien : « Inscription sur place dès 9 h », « SMS au 06… ».';
COMMENT ON COLUMN tournaments.verified_at IS 'Date « Vérifié le » affichée sur la fiche (RG-07).';
COMMENT ON COLUMN tournaments.source_note IS 'Usage interne : provenance de l''information (lien du post, e-mail…). Jamais exposé publiquement.';

-- Liste publique : tournois publiés triés par date, pagination par curseur
-- (start_date, id). Index partiel : ne contient que les tournois publiés.
CREATE INDEX tournaments_published_start_idx
    ON tournaments (start_date, id)
    WHERE publication_status = 'published';

-- Recherche texte sur le nom (insensible casse / accents, tolère les fautes)
CREATE INDEX tournaments_name_search_idx
    ON tournaments USING gin (search_normalize(name) gin_trgm_ops);

-- File de modération du back-office
CREATE INDEX tournaments_pending_idx
    ON tournaments (created_at)
    WHERE publication_status = 'pending';

-- Clés étrangères (accélèrent les jointures et les vérifications à la suppression)
CREATE INDEX tournaments_series_id_idx       ON tournaments (series_id);
CREATE INDEX tournaments_venue_id_idx        ON tournaments (venue_id);
CREATE INDEX tournaments_poster_media_id_idx ON tournaments (poster_media_id);

CREATE TRIGGER tournaments_set_updated_at
    BEFORE UPDATE ON tournaments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Tableaux d'une édition (RG-02)
-- Règle « au moins un tableau par édition publiée » : vérifiée par le service
-- (une contrainte SQL entre deux tables nécessiterait un déclencheur différé,
-- jugé inutilement complexe au MVP).
-- -----------------------------------------------------------------------------
CREATE TABLE tournament_divisions (
    id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id         uuid        NOT NULL REFERENCES tournaments (id) ON DELETE CASCADE,
    position              smallint    NOT NULL DEFAULT 0,
    format_code           text        NOT NULL REFERENCES formats (code),
    category_code         text        NOT NULL REFERENCES categories (code),
    surface_code          text        NOT NULL REFERENCES surfaces (code),
    players_per_team_min  smallint    NOT NULL CHECK (players_per_team_min BETWEEN 1 AND 12),
    players_per_team_max  smallint    NOT NULL CHECK (players_per_team_max BETWEEN 1 AND 12),
    -- Prix en centimes (entier : pas d'erreur d'arrondi). NULL = non communiqué, 0 = gratuit.
    price_cents           integer     CHECK (price_cents BETWEEN 0 AND 100000),
    price_unit            text        CHECK (price_unit IN ('team', 'player')),
    max_teams             smallint    CHECK (max_teams BETWEEN 1 AND 1000),
    schedule_note         text        CHECK (length(schedule_note) <= 200),
    conditions            text        CHECK (length(conditions)    <= 1000),
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tournament_divisions_players_order_chk
        CHECK (players_per_team_min <= players_per_team_max),
    CONSTRAINT tournament_divisions_paid_requires_unit_chk
        CHECK (price_cents IS NULL OR price_cents = 0 OR price_unit IS NOT NULL)
);
COMMENT ON TABLE tournament_divisions IS 'Tableaux d''une édition : format, catégorie, terrain, prix propres.';
COMMENT ON COLUMN tournament_divisions.price_cents IS 'NULL = non communiqué ; 0 = gratuit ; 1500 = 15,00 €.';
COMMENT ON COLUMN tournament_divisions.schedule_note IS 'Horaire libre : « matin », « à partir de 14 h ».';

CREATE INDEX tournament_divisions_tournament_id_idx ON tournament_divisions (tournament_id);

CREATE TRIGGER tournament_divisions_set_updated_at
    BEFORE UPDATE ON tournament_divisions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Niveaux d'un tableau (un tableau peut accueillir plusieurs niveaux)
-- -----------------------------------------------------------------------------
CREATE TABLE division_levels (
    division_id uuid NOT NULL REFERENCES tournament_divisions (id) ON DELETE CASCADE,
    level_code  text NOT NULL REFERENCES levels (code),
    PRIMARY KEY (division_id, level_code)
);
COMMENT ON TABLE division_levels IS 'Niveaux acceptés par un tableau (au moins un, vérifié par le service).';

CREATE INDEX division_levels_level_code_idx ON division_levels (level_code);

-- -----------------------------------------------------------------------------
-- Badges d'une édition
-- -----------------------------------------------------------------------------
CREATE TABLE tournament_tags (
    tournament_id uuid NOT NULL REFERENCES tournaments (id) ON DELETE CASCADE,
    tag_code      text NOT NULL REFERENCES tags (code),
    PRIMARY KEY (tournament_id, tag_code)
);

CREATE INDEX tournament_tags_tag_code_idx ON tournament_tags (tag_code);

-- +goose Down
DROP TABLE IF EXISTS tournament_tags;
DROP TABLE IF EXISTS division_levels;
DROP TABLE IF EXISTS tournament_divisions;
DROP TABLE IF EXISTS tournaments;
DROP TABLE IF EXISTS tournament_series;
