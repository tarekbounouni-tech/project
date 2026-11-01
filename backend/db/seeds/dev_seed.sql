-- =============================================================================
-- Données de DÉVELOPPEMENT — à ne JAMAIS exécuter en production
-- -----------------------------------------------------------------------------
-- * Quelques communes réelles de la zone pilote (l'import complet des
--   communes depuis l'API Géo sera fourni en phase 3).
-- * Organisateurs et tournois FICTIFS, uniquement pour tester l'application.
-- * Rejouable : le script vide d'abord les données de test.
--
-- Exécution :  psql "$DATABASE_URL" -f db/seeds/dev_seed.sql
-- =============================================================================

BEGIN;

TRUNCATE favorites, reports, submissions, tournament_daily_stats, audit_log,
         tournament_tags, division_levels, tournament_divisions, tournaments,
         tournament_series, venues, organizer_members, organizers, media,
         one_time_tokens, refresh_tokens, users
         CASCADE;

-- -----------------------------------------------------------------------------
-- Communes (codes INSEE réels, coordonnées approximatives du centre)
-- -----------------------------------------------------------------------------
INSERT INTO cities (insee_code, department_code, name, postal_codes, latitude, longitude) VALUES
    ('22278', '22', 'Saint-Brieuc',       '{22000}',                   48.514200, -2.765000),
    ('29019', '29', 'Brest',              '{29200}',                   48.390400, -4.486100),
    ('29232', '29', 'Quimper',            '{29000}',                   47.996000, -4.102400),
    ('35238', '35', 'Rennes',             '{35000,35200,35700}',       48.111700, -1.680000),
    ('35288', '35', 'Saint-Malo',         '{35400}',                   48.649300, -2.025700),
    ('44055', '44', 'La Baule-Escoublac', '{44500}',                   47.286600, -2.391000),
    ('44109', '44', 'Nantes',             '{44000,44100,44200,44300}', 47.218400, -1.553600),
    ('56034', '56', 'Carnac',             '{56340}',                   47.583900, -3.078500),
    ('56121', '56', 'Lorient',            '{56100}',                   47.748300, -3.370200),
    ('56260', '56', 'Vannes',             '{56000}',                   47.658600, -2.760200)
ON CONFLICT (insee_code) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Administrateur de test
-- e-mail : admin@example.com — le hachage ci-dessous est un exemple de FORMAT
-- et ne correspond à aucun mot de passe utilisable ; le compte administrateur
-- réel sera créé par une commande dédiée en phase 3.
-- -----------------------------------------------------------------------------
INSERT INTO users (id, email, password_hash, display_name, role_code, email_verified_at, privacy_policy_accepted_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'admin@example.com',
        '$argon2id$v=19$m=65536,t=3,p=2$ZXhhbXBsZXNhbHQ$ZXhhbXBsZWhhc2g', 'Admin', 'admin', now(), now());

-- -----------------------------------------------------------------------------
-- Organisateurs fictifs
-- -----------------------------------------------------------------------------
INSERT INTO organizers (id, name, type_code, description, city_insee, email, website_url, created_by) VALUES
    ('10000000-0000-0000-0000-000000000001', 'Volley Club Fictif de Vannes', 'club',
     'Club fictif utilisé pour les tests.', '56260', 'contact@vc-vannes.example', 'https://vc-vannes.example',
     '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000002', 'Comité des fêtes de Carnac (test)', 'municipality',
     NULL, '56034', NULL, NULL, '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000003', 'Rennes Beach Association (test)', 'association',
     'Association fictive de beach-volley.', '35238', 'hello@rennes-beach.example', NULL,
     '00000000-0000-0000-0000-000000000001');

-- -----------------------------------------------------------------------------
-- Lieux
-- -----------------------------------------------------------------------------
INSERT INTO venues (id, name, address_line, postal_code, city_insee, latitude, longitude, geocoding_source) VALUES
    ('20000000-0000-0000-0000-000000000001', 'Gymnase de test', '1 rue de l''Exemple', '56000', '56260', 47.660000, -2.755000, 'manual'),
    ('20000000-0000-0000-0000-000000000002', 'Grande Plage', 'Boulevard de la Plage', '56340', '56034', 47.572000, -3.070000, 'manual'),
    ('20000000-0000-0000-0000-000000000003', 'Terrains de beach du parc', NULL, '35000', '35238', 48.115000, -1.670000, 'city_center');

-- -----------------------------------------------------------------------------
-- Séries
-- -----------------------------------------------------------------------------
INSERT INTO tournament_series (id, organizer_id, name) VALUES
    ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Tournoi d''hiver de Vannes'),
    ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Tournoi de la Grande Plage'),
    ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'Rennes Beach Téléthon');

-- -----------------------------------------------------------------------------
-- Éditions : une passée, deux à venir (dates relatives à aujourd'hui pour que
-- les données restent pertinentes quel que soit le moment d'exécution)
-- -----------------------------------------------------------------------------
INSERT INTO tournaments (id, series_id, name, venue_id, start_date, end_date, start_time,
                         description, registration_mode, registration_url, registration_instructions,
                         registration_deadline, registration_status, publication_status, published_at,
                         contact_email, created_by) VALUES
    -- Édition passée de la série de Vannes
    ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001',
     'Tournoi d''hiver de Vannes 2025', '20000000-0000-0000-0000-000000000001',
     current_date - 300, current_date - 300, '09:00',
     'Édition précédente (fictive).', 'external_link', 'https://www.helloasso.com/exemple', NULL,
     NULL, 'closed', 'published', now() - interval '320 days',
     'contact@vc-vannes.example', '00000000-0000-0000-0000-000000000001'),
    -- Édition à venir, inscriptions ouvertes, clôture proche (badge calculé)
    ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001',
     'Tournoi d''hiver de Vannes', '20000000-0000-0000-0000-000000000001',
     current_date + 20, current_date + 20, '09:00',
     'Tournoi 4x4 mixte en salle, buvette sur place (fictif).', 'external_link', 'https://www.helloasso.com/exemple', NULL,
     current_date + 5, 'open', 'published', now(),
     'contact@vc-vannes.example', '00000000-0000-0000-0000-000000000001'),
    -- Tournoi sur sable sur deux jours, inscription sur place
    ('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000002',
     'Tournoi de la Grande Plage', '20000000-0000-0000-0000-000000000002',
     current_date + 60, current_date + 61, '10:00',
     'Deux tableaux sur sable (fictif).', 'on_site', NULL, 'Inscriptions sur place à partir de 9 h.',
     NULL, 'not_open_yet', 'published', now(),
     NULL, '00000000-0000-0000-0000-000000000001'),
    -- Brouillon (non visible dans l'app)
    ('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000003',
     'Rennes Beach Téléthon', '20000000-0000-0000-0000-000000000003',
     current_date + 90, current_date + 90, NULL,
     NULL, 'external_link', 'https://forms.example/telethon', NULL,
     NULL, 'not_open_yet', 'draft', NULL,
     NULL, '00000000-0000-0000-0000-000000000001');

-- -----------------------------------------------------------------------------
-- Tableaux
-- -----------------------------------------------------------------------------
INSERT INTO tournament_divisions (id, tournament_id, position, format_code, category_code, surface_code,
                                  players_per_team_min, players_per_team_max, price_cents, price_unit,
                                  max_teams, schedule_note) VALUES
    ('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 0, '4x4', 'mixed', 'indoor', 4, 6, 2000, 'team', 24, NULL),
    ('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', 0, '4x4', 'mixed', 'indoor', 4, 6, 2400, 'team', 24, NULL),
    ('50000000-0000-0000-0000-000000000003', '40000000-0000-0000-0000-000000000003', 0, '2x2', 'men',   'sand',   2, 2, 1000, 'player', 32, 'Samedi'),
    ('50000000-0000-0000-0000-000000000004', '40000000-0000-0000-0000-000000000003', 1, '2x2', 'women', 'sand',   2, 2, 1000, 'player', 32, 'Samedi'),
    ('50000000-0000-0000-0000-000000000005', '40000000-0000-0000-0000-000000000003', 2, '4x4', 'mixed', 'sand',   4, 5, 0,    NULL,     16, 'Dimanche'),
    ('50000000-0000-0000-0000-000000000006', '40000000-0000-0000-0000-000000000004', 0, '3x3', 'open',  'sand',   3, 4, NULL, NULL,     NULL, NULL);

INSERT INTO division_levels (division_id, level_code) VALUES
    ('50000000-0000-0000-0000-000000000001', 'leisure'),
    ('50000000-0000-0000-0000-000000000002', 'leisure'),
    ('50000000-0000-0000-0000-000000000002', 'intermediate'),
    ('50000000-0000-0000-0000-000000000003', 'intermediate'),
    ('50000000-0000-0000-0000-000000000003', 'advanced'),
    ('50000000-0000-0000-0000-000000000004', 'intermediate'),
    ('50000000-0000-0000-0000-000000000004', 'advanced'),
    ('50000000-0000-0000-0000-000000000005', 'beginner'),
    ('50000000-0000-0000-0000-000000000005', 'leisure'),
    ('50000000-0000-0000-0000-000000000006', 'leisure');

INSERT INTO tournament_tags (tournament_id, tag_code) VALUES
    ('40000000-0000-0000-0000-000000000004', 'telethon'),
    ('40000000-0000-0000-0000-000000000004', 'charity');

COMMIT;
