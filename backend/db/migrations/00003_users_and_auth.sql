-- =============================================================================
-- Migration 00003 — Utilisateurs et authentification
-- -----------------------------------------------------------------------------
-- Données personnelles minimales (RGPD) : e-mail, pseudo, département préféré.
-- La suppression d'un utilisateur est DÉFINITIVE (DELETE) et entraîne en
-- cascade la suppression de ses sessions, jetons et favoris (RG-15).
-- Les contenus qu'il a créés côté back-office (tournois…) sont conservés,
-- leur auteur devenant NULL (ON DELETE SET NULL dans les migrations suivantes).
-- =============================================================================

-- +goose Up

-- -----------------------------------------------------------------------------
-- Utilisateurs
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    id                         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    email                      citext      NOT NULL UNIQUE
                                           CHECK (length(email) <= 254 AND email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    password_hash              text        NOT NULL,
    display_name               text        CHECK (length(display_name) BETWEEN 2 AND 50),
    role_code                  text        NOT NULL DEFAULT 'user' REFERENCES roles (code),
    preferred_department_code  text        REFERENCES departments (code) ON DELETE SET NULL,
    email_verified_at          timestamptz,
    privacy_policy_accepted_at timestamptz NOT NULL,
    last_login_at              timestamptz,
    created_at                 timestamptz NOT NULL DEFAULT now(),
    updated_at                 timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE users IS 'Comptes utilisateurs (utilisateurs, organisateurs, administrateurs).';
COMMENT ON COLUMN users.email IS 'Insensible à la casse (citext). Validation fine faite par l''API.';
COMMENT ON COLUMN users.password_hash IS 'Hachage Argon2id au format PHC ($argon2id$v=19$m=…). Jamais le mot de passe.';
COMMENT ON COLUMN users.privacy_policy_accepted_at IS 'Preuve de l''acceptation de la politique de confidentialité (RGPD).';

CREATE INDEX users_role_code_idx ON users (role_code) WHERE role_code <> 'user';

CREATE TRIGGER users_set_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Jetons de renouvellement (sessions)
-- Le jeton lui-même n'est jamais stocké : seulement son empreinte SHA-256.
-- family_id regroupe tous les jetons issus d'une même connexion : si un jeton
-- déjà utilisé est présenté à nouveau (vol probable), toute la famille est
-- révoquée (détection de réutilisation).
-- -----------------------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    family_id   uuid        NOT NULL,
    token_hash  bytea       NOT NULL UNIQUE CHECK (length(token_hash) = 32),
    expires_at  timestamptz NOT NULL,
    used_at     timestamptz,
    revoked_at  timestamptz,
    user_agent  text        CHECK (length(user_agent) <= 300),
    created_at  timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > created_at)
);
COMMENT ON TABLE refresh_tokens IS 'Sessions : jetons de renouvellement rotatifs (empreinte SHA-256 uniquement).';

CREATE INDEX refresh_tokens_user_id_idx   ON refresh_tokens (user_id);
CREATE INDEX refresh_tokens_family_id_idx ON refresh_tokens (family_id);
-- Purge périodique des jetons expirés
CREATE INDEX refresh_tokens_expires_at_idx ON refresh_tokens (expires_at);

-- -----------------------------------------------------------------------------
-- Jetons à usage unique : vérification d'e-mail, réinitialisation de mot de passe
-- -----------------------------------------------------------------------------
CREATE TABLE one_time_tokens (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    purpose     text        NOT NULL CHECK (purpose IN ('email_verification', 'password_reset')),
    token_hash  bytea       NOT NULL UNIQUE CHECK (length(token_hash) = 32),
    expires_at  timestamptz NOT NULL,
    used_at     timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > created_at)
);
COMMENT ON TABLE one_time_tokens IS 'Liens envoyés par e-mail (24 h pour la vérification, 1 h pour le mot de passe).';

CREATE INDEX one_time_tokens_user_purpose_idx ON one_time_tokens (user_id, purpose);
CREATE INDEX one_time_tokens_expires_at_idx   ON one_time_tokens (expires_at);

-- +goose Down
DROP TABLE IF EXISTS one_time_tokens;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS users;
