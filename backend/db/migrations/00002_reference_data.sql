-- =============================================================================
-- Migration 00002 — Référentiels (tables de valeurs) et géographie
-- -----------------------------------------------------------------------------
-- Choix de conception :
--   * Les valeurs métier « listables » (formats, niveaux, terrains, badges…)
--     sont des TABLES de référence avec une clé texte lisible ('2x2', 'sand')
--     plutôt que des types ENUM PostgreSQL : on peut ajouter une valeur ou
--     changer un libellé par un simple INSERT/UPDATE, sans migration de type,
--     et le back-office peut lister les valeurs via l'API.
--   * Les STATUTS (cycle de vie) restent des colonnes texte avec contrainte
--     CHECK dans les tables concernées : ils sont liés au code (machine à
--     états) et ne doivent pas être modifiables par les données.
--   * Les données de référence indispensables au fonctionnement de
--     l'application sont insérées ici même : la base est utilisable dès la
--     fin des migrations, en local comme en production.
--   * Les communes (~35 000) sont chargées séparément par un script
--     d'import depuis l'API Géo officielle (phase 3), pas par migration.
-- =============================================================================

-- +goose Up

-- -----------------------------------------------------------------------------
-- Rôles des utilisateurs
-- -----------------------------------------------------------------------------
CREATE TABLE roles (
    code   text PRIMARY KEY,
    label  text NOT NULL
);
COMMENT ON TABLE roles IS 'Rôles applicatifs. Un utilisateur a exactement un rôle.';

INSERT INTO roles (code, label) VALUES
    ('user',      'Utilisateur'),
    ('organizer', 'Organisateur'),   -- interface livrée en V2
    ('admin',     'Administrateur');

-- -----------------------------------------------------------------------------
-- Formats de jeu
-- -----------------------------------------------------------------------------
CREATE TABLE formats (
    code             text PRIMARY KEY,
    label            text     NOT NULL,
    players_on_court smallint CHECK (players_on_court BETWEEN 1 AND 12),
    sort_order       smallint NOT NULL DEFAULT 0
);
COMMENT ON TABLE formats IS 'Formats de jeu (2x2, 4x4…). players_on_court NULL pour « autre ».';

INSERT INTO formats (code, label, players_on_court, sort_order) VALUES
    ('2x2',   '2x2',   2,    10),
    ('3x3',   '3x3',   3,    20),
    ('4x4',   '4x4',   4,    30),
    ('6x6',   '6x6',   6,    40),
    ('other', 'Autre', NULL, 99);

-- -----------------------------------------------------------------------------
-- Catégories (type de tournoi)
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    code       text PRIMARY KEY,
    label      text     NOT NULL,
    sort_order smallint NOT NULL DEFAULT 0
);
COMMENT ON TABLE categories IS 'Type de tableau : masculin, féminin, mixte, libre.';

INSERT INTO categories (code, label, sort_order) VALUES
    ('men',   'Masculin', 10),
    ('women', 'Féminin',  20),
    ('mixed', 'Mixte',    30),
    ('open',  'Libre',    40);

-- -----------------------------------------------------------------------------
-- Niveaux
-- -----------------------------------------------------------------------------
CREATE TABLE levels (
    code       text PRIMARY KEY,
    label      text     NOT NULL,
    sort_order smallint NOT NULL DEFAULT 0
);
COMMENT ON TABLE levels IS 'Niveaux de jeu, ordonnés du plus accessible au plus exigeant.';

INSERT INTO levels (code, label, sort_order) VALUES
    ('beginner',     'Débutant',      10),
    ('leisure',      'Loisir',        20),
    ('intermediate', 'Intermédiaire', 30),
    ('advanced',     'Confirmé',      40),
    ('competitive',  'Compétition',   50);

-- -----------------------------------------------------------------------------
-- Types de terrain
-- -----------------------------------------------------------------------------
CREATE TABLE surfaces (
    code       text PRIMARY KEY,
    label      text     NOT NULL,
    sort_order smallint NOT NULL DEFAULT 0
);
COMMENT ON TABLE surfaces IS 'Type de terrain : intérieur, extérieur (herbe, synthétique), sable.';

INSERT INTO surfaces (code, label, sort_order) VALUES
    ('indoor',  'Intérieur', 10),
    ('outdoor', 'Extérieur', 20),
    ('sand',    'Sable',     30);

-- -----------------------------------------------------------------------------
-- Badges attribués manuellement
-- Le badge « Inscriptions bientôt clôturées » n'est PAS ici : il est calculé
-- (règle RG-08) à partir de la date limite d'inscription.
-- -----------------------------------------------------------------------------
CREATE TABLE tags (
    code       text PRIMARY KEY,
    label      text     NOT NULL,
    sort_order smallint NOT NULL DEFAULT 0
);
COMMENT ON TABLE tags IS 'Badges manuels affichés sur les tournois.';

INSERT INTO tags (code, label, sort_order) VALUES
    ('charity',    'Caritatif', 10),
    ('telethon',   'Téléthon',  20),
    ('solidarity', 'Solidaire', 30),
    ('special',    'Spécial',   40);

-- -----------------------------------------------------------------------------
-- Types d'organisateurs
-- -----------------------------------------------------------------------------
CREATE TABLE organizer_types (
    code       text PRIMARY KEY,
    label      text     NOT NULL,
    sort_order smallint NOT NULL DEFAULT 0
);

INSERT INTO organizer_types (code, label, sort_order) VALUES
    ('club',         'Club',                         10),
    ('association',  'Association',                  20),
    ('municipality', 'Collectivité / comité des fêtes', 30),
    ('business',     'Entreprise / établissement',   40),
    ('individual',   'Particulier',                  50),
    ('other',        'Autre',                        99);

-- =============================================================================
-- GÉOGRAPHIE — codes officiels INSEE (Code officiel géographique)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Régions
-- -----------------------------------------------------------------------------
CREATE TABLE regions (
    code text PRIMARY KEY CHECK (code ~ '^[0-9]{2}$'),
    name text NOT NULL UNIQUE
);
COMMENT ON TABLE regions IS 'Régions de France métropolitaine (code INSEE à 2 chiffres).';

INSERT INTO regions (code, name) VALUES
    ('11', 'Île-de-France'),
    ('24', 'Centre-Val de Loire'),
    ('27', 'Bourgogne-Franche-Comté'),
    ('28', 'Normandie'),
    ('32', 'Hauts-de-France'),
    ('44', 'Grand Est'),
    ('52', 'Pays de la Loire'),
    ('53', 'Bretagne'),
    ('75', 'Nouvelle-Aquitaine'),
    ('76', 'Occitanie'),
    ('84', 'Auvergne-Rhône-Alpes'),
    ('93', 'Provence-Alpes-Côte d''Azur'),
    ('94', 'Corse');

-- -----------------------------------------------------------------------------
-- Départements
-- is_active : département ouvert dans l'application (zone pilote au lancement).
-- Ouvrir un nouveau département = UPDATE departments SET is_active = true.
-- -----------------------------------------------------------------------------
CREATE TABLE departments (
    code        text PRIMARY KEY CHECK (code ~ '^([0-9]{2}|2A|2B)$'),
    region_code text    NOT NULL REFERENCES regions (code),
    name        text    NOT NULL UNIQUE,
    is_active   boolean NOT NULL DEFAULT false
);
COMMENT ON TABLE departments IS 'Départements métropolitains (2A/2B pour la Corse).';
COMMENT ON COLUMN departments.is_active IS 'true = département couvert par l''application et proposé dans les filtres.';

CREATE INDEX departments_region_code_idx ON departments (region_code);

INSERT INTO departments (code, region_code, name) VALUES
    ('01', '84', 'Ain'),
    ('02', '32', 'Aisne'),
    ('03', '84', 'Allier'),
    ('04', '93', 'Alpes-de-Haute-Provence'),
    ('05', '93', 'Hautes-Alpes'),
    ('06', '93', 'Alpes-Maritimes'),
    ('07', '84', 'Ardèche'),
    ('08', '44', 'Ardennes'),
    ('09', '76', 'Ariège'),
    ('10', '44', 'Aube'),
    ('11', '76', 'Aude'),
    ('12', '76', 'Aveyron'),
    ('13', '93', 'Bouches-du-Rhône'),
    ('14', '28', 'Calvados'),
    ('15', '84', 'Cantal'),
    ('16', '75', 'Charente'),
    ('17', '75', 'Charente-Maritime'),
    ('18', '24', 'Cher'),
    ('19', '75', 'Corrèze'),
    ('2A', '94', 'Corse-du-Sud'),
    ('2B', '94', 'Haute-Corse'),
    ('21', '27', 'Côte-d''Or'),
    ('22', '53', 'Côtes-d''Armor'),
    ('23', '75', 'Creuse'),
    ('24', '75', 'Dordogne'),
    ('25', '27', 'Doubs'),
    ('26', '84', 'Drôme'),
    ('27', '28', 'Eure'),
    ('28', '24', 'Eure-et-Loir'),
    ('29', '53', 'Finistère'),
    ('30', '76', 'Gard'),
    ('31', '76', 'Haute-Garonne'),
    ('32', '76', 'Gers'),
    ('33', '75', 'Gironde'),
    ('34', '76', 'Hérault'),
    ('35', '53', 'Ille-et-Vilaine'),
    ('36', '24', 'Indre'),
    ('37', '24', 'Indre-et-Loire'),
    ('38', '84', 'Isère'),
    ('39', '27', 'Jura'),
    ('40', '75', 'Landes'),
    ('41', '24', 'Loir-et-Cher'),
    ('42', '84', 'Loire'),
    ('43', '84', 'Haute-Loire'),
    ('44', '52', 'Loire-Atlantique'),
    ('45', '24', 'Loiret'),
    ('46', '76', 'Lot'),
    ('47', '75', 'Lot-et-Garonne'),
    ('48', '76', 'Lozère'),
    ('49', '52', 'Maine-et-Loire'),
    ('50', '28', 'Manche'),
    ('51', '44', 'Marne'),
    ('52', '44', 'Haute-Marne'),
    ('53', '52', 'Mayenne'),
    ('54', '44', 'Meurthe-et-Moselle'),
    ('55', '44', 'Meuse'),
    ('56', '53', 'Morbihan'),
    ('57', '44', 'Moselle'),
    ('58', '27', 'Nièvre'),
    ('59', '32', 'Nord'),
    ('60', '32', 'Oise'),
    ('61', '28', 'Orne'),
    ('62', '32', 'Pas-de-Calais'),
    ('63', '84', 'Puy-de-Dôme'),
    ('64', '75', 'Pyrénées-Atlantiques'),
    ('65', '76', 'Hautes-Pyrénées'),
    ('66', '76', 'Pyrénées-Orientales'),
    ('67', '44', 'Bas-Rhin'),
    ('68', '44', 'Haut-Rhin'),
    ('69', '84', 'Rhône'),
    ('70', '27', 'Haute-Saône'),
    ('71', '27', 'Saône-et-Loire'),
    ('72', '52', 'Sarthe'),
    ('73', '84', 'Savoie'),
    ('74', '84', 'Haute-Savoie'),
    ('75', '11', 'Paris'),
    ('76', '28', 'Seine-Maritime'),
    ('77', '11', 'Seine-et-Marne'),
    ('78', '11', 'Yvelines'),
    ('79', '75', 'Deux-Sèvres'),
    ('80', '32', 'Somme'),
    ('81', '76', 'Tarn'),
    ('82', '76', 'Tarn-et-Garonne'),
    ('83', '93', 'Var'),
    ('84', '93', 'Vaucluse'),
    ('85', '52', 'Vendée'),
    ('86', '75', 'Vienne'),
    ('87', '75', 'Haute-Vienne'),
    ('88', '44', 'Vosges'),
    ('89', '27', 'Yonne'),
    ('90', '27', 'Territoire de Belfort'),
    ('91', '11', 'Essonne'),
    ('92', '11', 'Hauts-de-Seine'),
    ('93', '11', 'Seine-Saint-Denis'),
    ('94', '11', 'Val-de-Marne'),
    ('95', '11', 'Val-d''Oise');

-- Zone pilote : Bretagne historique (4 départements bretons + Loire-Atlantique)
UPDATE departments SET is_active = true WHERE code IN ('22', '29', '35', '44', '56');

-- -----------------------------------------------------------------------------
-- Communes
-- Chargées par script depuis l'API Géo (geo.api.gouv.fr).
-- Une commune peut avoir plusieurs codes postaux (ex. grandes villes) :
-- tableau postal_codes. latitude/longitude = centre de la commune (sert de
-- position par défaut si une adresse précise n'est pas connue).
-- -----------------------------------------------------------------------------
CREATE TABLE cities (
    insee_code      text PRIMARY KEY CHECK (insee_code ~ '^([0-9]{2}|2A|2B)[0-9]{3}$'),
    department_code text   NOT NULL REFERENCES departments (code),
    name            text   NOT NULL,
    postal_codes    text[] NOT NULL DEFAULT '{}',
    latitude        numeric(8, 6) CHECK (latitude  BETWEEN -90  AND 90),
    longitude       numeric(9, 6) CHECK (longitude BETWEEN -180 AND 180),
    population      integer CHECK (population >= 0)
);
COMMENT ON TABLE cities IS 'Communes (code INSEE), importées depuis l''API Géo officielle.';
COMMENT ON COLUMN cities.postal_codes IS 'Tous les codes postaux de la commune.';

CREATE INDEX cities_department_code_idx ON cities (department_code);
-- Recherche de commune par nom (auto-complétion, recherche texte des tournois)
CREATE INDEX cities_name_search_idx ON cities USING gin (search_normalize(name) gin_trgm_ops);
-- Recherche par code postal (« 56340 »)
CREATE INDEX cities_postal_codes_idx ON cities USING gin (postal_codes);

-- +goose Down
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS organizer_types;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS surfaces;
DROP TABLE IF EXISTS levels;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS formats;
DROP TABLE IF EXISTS roles;
