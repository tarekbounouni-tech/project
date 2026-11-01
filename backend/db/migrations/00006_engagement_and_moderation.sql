-- =============================================================================
-- Migration 00006 — Favoris, propositions, signalements, statistiques, audit
-- -----------------------------------------------------------------------------
-- RGPD : les formulaires anonymes (propositions, signalements) conservent une
-- empreinte d'IP (ip_hash = HMAC-SHA256 de l'IP avec une clé secrète) servant
-- uniquement à lutter contre les abus. Elle est effacée après 30 jours par une
-- tâche de purge (phase 3). Aucune adresse IP en clair n'est stockée.
-- =============================================================================

-- +goose Up

-- -----------------------------------------------------------------------------
-- Favoris
-- -----------------------------------------------------------------------------
CREATE TABLE favorites (
    user_id       uuid        NOT NULL REFERENCES users (id)       ON DELETE CASCADE,
    tournament_id uuid        NOT NULL REFERENCES tournaments (id) ON DELETE CASCADE,
    created_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, tournament_id)
);
COMMENT ON TABLE favorites IS 'Tournois mis en favori par les utilisateurs. La clé primaire empêche les doublons.';

-- La clé primaire couvre « favoris d'un utilisateur » ; cet index couvre
-- « qui a mis ce tournoi en favori » (notifications V2, suppression).
CREATE INDEX favorites_tournament_id_idx ON favorites (tournament_id);

-- -----------------------------------------------------------------------------
-- Propositions de tournois (formulaire public, RG-09)
-- Quelques champs structurés pour la file de modération et la détection de
-- doublons ; l'intégralité du formulaire est conservée dans payload (JSON).
-- -----------------------------------------------------------------------------
CREATE TABLE submissions (
    id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    status                text        NOT NULL DEFAULT 'pending'
                                      CHECK (status IN ('pending', 'accepted', 'rejected', 'spam')),
    tournament_name       text        NOT NULL CHECK (length(tournament_name) BETWEEN 2 AND 150),
    start_date            date        NOT NULL,
    city_name             text        NOT NULL CHECK (length(city_name) BETWEEN 1 AND 100),
    city_insee            text        REFERENCES cities (insee_code),
    source_url            text        CHECK (source_url ~ '^https?://' AND length(source_url) <= 2000),
    payload               jsonb       NOT NULL DEFAULT '{}'::jsonb
                                      CHECK (jsonb_typeof(payload) = 'object'),
    submitter_email       citext      CHECK (submitter_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    submitted_by          uuid        REFERENCES users (id) ON DELETE SET NULL,
    poster_media_id       uuid        REFERENCES media (id) ON DELETE SET NULL,
    created_tournament_id uuid        REFERENCES tournaments (id) ON DELETE SET NULL,
    reviewed_by           uuid        REFERENCES users (id) ON DELETE SET NULL,
    reviewed_at           timestamptz,
    rejection_reason      text        CHECK (length(rejection_reason) <= 1000),
    ip_hash               bytea       CHECK (length(ip_hash) = 32),
    created_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT submissions_reviewed_when_closed_chk
        CHECK (status = 'pending' OR reviewed_at IS NOT NULL),
    CONSTRAINT submissions_rejected_requires_reason_chk
        CHECK (status <> 'rejected' OR rejection_reason IS NOT NULL)
);
COMMENT ON TABLE submissions IS 'Tournois proposés par des tiers, en attente de modération.';
COMMENT ON COLUMN submissions.payload IS 'Formulaire complet tel que saisi (formats, prix, description…).';
COMMENT ON COLUMN submissions.ip_hash IS 'HMAC de l''IP, anti-abus uniquement, purgé après 30 jours.';

CREATE INDEX submissions_pending_idx
    ON submissions (created_at)
    WHERE status = 'pending';
CREATE INDEX submissions_ip_hash_idx
    ON submissions (ip_hash, created_at)
    WHERE ip_hash IS NOT NULL;

-- -----------------------------------------------------------------------------
-- Signalements d'erreurs (RG-11)
-- -----------------------------------------------------------------------------
CREATE TABLE reports (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid        NOT NULL REFERENCES tournaments (id) ON DELETE CASCADE,
    reason        text        NOT NULL
                              CHECK (reason IN ('wrong_date', 'cancelled', 'dead_link', 'full', 'other')),
    comment       text        CHECK (length(comment) <= 1000),
    status        text        NOT NULL DEFAULT 'open'
                              CHECK (status IN ('open', 'resolved', 'dismissed')),
    reported_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
    resolved_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
    resolved_at   timestamptz,
    ip_hash       bytea       CHECK (length(ip_hash) = 32),
    created_at    timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT reports_resolved_when_closed_chk
        CHECK (status = 'open' OR resolved_at IS NOT NULL)
);
COMMENT ON TABLE reports IS 'Signalements d''informations erronées sur une fiche tournoi.';

CREATE INDEX reports_tournament_id_idx ON reports (tournament_id);
CREATE INDEX reports_open_idx
    ON reports (created_at)
    WHERE status = 'open';

-- -----------------------------------------------------------------------------
-- Statistiques anonymes par tournoi et par jour (RG-16)
-- Incrémentées par INSERT … ON CONFLICT DO UPDATE (une ligne par jour).
-- -----------------------------------------------------------------------------
CREATE TABLE tournament_daily_stats (
    tournament_id       uuid    NOT NULL REFERENCES tournaments (id) ON DELETE CASCADE,
    day                 date    NOT NULL,
    views               integer NOT NULL DEFAULT 0 CHECK (views >= 0),
    registration_clicks integer NOT NULL DEFAULT 0 CHECK (registration_clicks >= 0),
    PRIMARY KEY (tournament_id, day)
);
COMMENT ON TABLE tournament_daily_stats IS 'Compteurs anonymes : vues de fiche et clics « S''inscrire ». Aucune donnée personnelle.';

-- -----------------------------------------------------------------------------
-- Journal d'audit des actions du back-office (ADM-04)
-- Identifiant séquentiel : ordre chronologique garanti, volume modeste.
-- -----------------------------------------------------------------------------
CREATE TABLE audit_log (
    id            bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_user_id uuid        REFERENCES users (id) ON DELETE SET NULL,
    entity_type   text        NOT NULL
                              CHECK (entity_type IN ('tournament', 'series', 'division', 'organizer',
                                                     'venue', 'submission', 'report', 'user', 'media')),
    entity_id     uuid        NOT NULL,
    action        text        NOT NULL CHECK (action ~ '^[a-z_]{2,40}$'),
    changes       jsonb,
    created_at    timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE audit_log IS 'Historique des modifications (qui, quoi, quand). Ex. action = publish, changes = {"before":…,"after":…}.';

CREATE INDEX audit_log_entity_idx ON audit_log (entity_type, entity_id, created_at DESC);

-- +goose Down
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS tournament_daily_stats;
DROP TABLE IF EXISTS reports;
DROP TABLE IF EXISTS submissions;
DROP TABLE IF EXISTS favorites;
