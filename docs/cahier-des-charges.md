# Cahier des charges fonctionnel — Plateforme de tournois de volley-ball

| | |
|---|---|
| **Version** | 1.1 — validée |
| **Date** | 1er novembre 2026 |
| **Nom de travail** | VolleySpot (provisoire) |
| **Statut** | Validé le 1er novembre 2026 (phase 1 terminée) |

> Ce document est la référence de toutes les étapes suivantes. Toute modification du périmètre doit y être reportée (avec une nouvelle version) avant d'être développée.

---

## Sommaire

1. [Contexte et objectifs](#1-contexte-et-objectifs)
2. [Utilisateurs et rôles](#2-utilisateurs-et-rôles)
3. [Périmètre : MVP, V2 et hors périmètre](#3-périmètre--mvp-v2-et-hors-périmètre)
4. [Fonctionnalités détaillées (user stories)](#4-fonctionnalités-détaillées-user-stories)
5. [Règles métier](#5-règles-métier)
6. [Contenu d'une fiche tournoi](#6-contenu-dune-fiche-tournoi)
7. [Modèle de données conceptuel](#7-modèle-de-données-conceptuel)
8. [Navigation et écrans](#8-navigation-et-écrans)
9. [Identité visuelle](#9-identité-visuelle)
10. [Alimentation du catalogue](#10-alimentation-du-catalogue)
11. [Exigences non fonctionnelles](#11-exigences-non-fonctionnelles)
12. [Stack technique retenue](#12-stack-technique-retenue)
13. [Infrastructure et budget](#13-infrastructure-et-budget)
14. [Indicateurs de succès](#14-indicateurs-de-succès)
15. [Roadmap](#15-roadmap)
16. [Hypothèses et points ouverts](#16-hypothèses-et-points-ouverts)
17. [Glossaire](#17-glossaire)

---

## 1. Contexte et objectifs

### 1.1 Problème

Les tournois de volley-ball « libres » (organisés par des clubs, associations, comités des fêtes…) sont annoncés de façon dispersée : pages Facebook et Instagram, HelloAsso, Google Forms, sites de clubs, bouche-à-oreille. Résultat pour un joueur :

- **HelloAsso** : la recherche d'un tournoi de volley est peu pratique (pas de filtres adaptés au volley : format, niveau, terrain).
- **Facebook** : informations souvent pas mises à jour (dates, inscriptions complètes, annulations).
- Aucune vue d'ensemble des tournois d'une région.

### 1.2 Proposition de valeur

> **Trouver en moins d'une minute un tournoi de volley près de chez soi, avec des informations fiables et à jour.**

Les deux différenciateurs, qui guident toutes les priorités :

1. **Une recherche pensée pour le volley** (format 2x2/3x3/4x4/6x6, type, niveau, terrain).
2. **La fiabilité des informations** (validation, date de vérification affichée, signalement des erreurs, statuts d'inscription tenus à jour).

### 1.3 Nature du projet

- Projet **personnel et d'apprentissage**, développé par une seule personne avec l'accompagnement de Claude.
- Exigence de **qualité professionnelle** (architecture, tests, sécurité, CI/CD), sans objectif commercial à court terme.
- **Aucune monétisation au MVP** ; l'architecture n'empêche pas des évolutions futures.

### 1.4 Périmètre géographique

- **Lancement : Bretagne historique** (zone pilote) — Côtes-d'Armor (22), Finistère (29), Ille-et-Vilaine (35), Morbihan (56) et Loire-Atlantique (44, rattachée administrativement aux Pays de la Loire).
- **Architecture prévue dès le départ pour la France métropolitaine** (toutes les régions et départements présents en base, activation progressive).
- Hors périmètre : DOM-TOM, pays étrangers.

### 1.5 Objectif de calendrier

Première version publiée sur Google Play **avant la saison beach 2027 (mai-juin 2027)**.

---

## 2. Utilisateurs et rôles

### 2.1 Personas

| Persona | Description | Besoin principal |
|---|---|---|
| **Léa, joueuse loisir** (cible n°1) | 27 ans, joue en salle l'hiver et sur sable l'été, cherche des tournois mixtes le week-end avec ses amis. | Voir rapidement les prochains tournois mixtes 4x4 ou 2x2 dans son département et accéder au lien d'inscription. |
| **Thomas, joueur intermédiaire / confirmé** | 32 ans, ancien licencié, joue des tournois 2x2 sable de bon niveau. | Filtrer par niveau et format, suivre ses tournois favoris, ne pas rater les clôtures d'inscription. |
| **Association organisatrice** | Bénévole d'un club ou d'un comité des fêtes qui organise 1 à 3 tournois par an. | Faire connaître son tournoi gratuitement, sans créer de compte compliqué. |
| **Administrateur** (le porteur du projet) | Alimente et modère le catalogue. | Saisir ou valider un tournoi en moins de 2 minutes, traiter les signalements. |

### 2.2 Rôles et permissions

| Action | Visiteur (sans compte) | Utilisateur connecté | Administrateur | Organisateur *(V2)* |
|---|:-:|:-:|:-:|:-:|
| Consulter, rechercher, filtrer les tournois | ✅ | ✅ | ✅ | ✅ |
| Consulter les fiches club / organisateur | ✅ | ✅ | ✅ | ✅ |
| Ouvrir le lien d'inscription externe | ✅ | ✅ | ✅ | ✅ |
| Proposer un tournoi (formulaire) | ✅ | ✅ | ✅ | ✅ |
| Signaler une erreur sur une fiche | ✅ | ✅ | ✅ | ✅ |
| Ajouter / retirer des favoris | ❌ | ✅ | ✅ | ✅ |
| Gérer son compte (modifier, supprimer) | ❌ | ✅ | ✅ | ✅ |
| Accéder au back-office web | ❌ | ❌ | ✅ | ❌ |
| Créer / modifier / publier / archiver un tournoi | ❌ | ❌ | ✅ | ✅ *(ses tournois, soumis à validation)* |
| Créer / modifier un organisateur | ❌ | ❌ | ✅ | ✅ *(son profil)* |
| Valider / refuser une proposition | ❌ | ❌ | ✅ | ❌ |
| Traiter les signalements | ❌ | ❌ | ✅ | ❌ |

> Le rôle **Organisateur** est modélisé dès le MVP (base de données et API) mais son interface n'est livrée qu'en V2.

---

## 3. Périmètre : MVP, V2 et hors périmètre

### 3.1 MVP (version 1.0)

**Application mobile (Android, iOS compilable)**
- Liste chronologique des tournois à venir, groupée par mois.
- Recherche texte (nom du tournoi, organisateur, ville).
- Filtres : période, département, format, type, niveau, terrain.
- Fiche détaillée d'un tournoi (avec ses tableaux, badges, statut d'inscription, date de vérification).
- Bouton « S'inscrire » vers le lien externe (ou mention « sur place » / « par téléphone »).
- Fiche organisateur avec la liste de ses tournois.
- Historique des tournois passés.
- Formulaire « Proposer un tournoi » (sans compte).
- Bouton « Signaler une erreur » (sans compte).
- Création de compte (e-mail + mot de passe), connexion, mot de passe oublié, suppression du compte.
- Favoris (liste « Mes tournois » : à venir / passés).
- Mode clair / sombre automatique.

**Back-office web (administrateur uniquement)**
- Connexion administrateur.
- Gestion des tournois : créer, modifier, dupliquer une édition, publier, annuler, reporter, archiver.
- Gestion des organisateurs.
- File de validation des propositions (valider / modifier / refuser avec motif).
- File de traitement des signalements.
- Upload d'affiches.
- Statistiques simples (vues et clics « S'inscrire » par tournoi).

**Backend (API REST Go)**
- API publique (consultation), API utilisateur (compte, favoris), API administrateur.
- Authentification, rôles, validation des données, journalisation, documentation OpenAPI.

### 3.2 V2 (après le lancement, par ordre de priorité indicatif)

1. Notifications push (nouveau tournoi correspondant à mes critères, clôture des inscriptions d'un favori, annulation d'un favori).
2. Filtre par distance (« autour de moi ») et vue carte.
3. Espace organisateur (compte organisateur, revendication d'un profil club, gestion de ses tournois soumise à validation).
4. Connexion avec Google et Apple.
5. Pré-remplissage assisté par IA d'un tournoi à partir d'un texte ou d'une photo d'affiche (back-office).
6. Alertes « édition non encore annoncée » pour les séries récurrentes.
7. Ouverture à d'autres régions.
8. Publication sur l'App Store (iOS).

### 3.3 Hors périmètre (explicitement exclu)

- Compétitions officielles FFVolley (championnats, circuits homologués).
- Recherche de coéquipiers / constitution d'équipes.
- Inscription et paiement intégrés (architecture compatible, non développé).
- Nombre de places restantes en temps réel.
- Vue calendrier.
- Collecte automatisée (scraping) des réseaux sociaux.
- Publicité, abonnements, traçage publicitaire.
- DOM-TOM et international.
- Multilingue (textes externalisés, français uniquement).

---

## 4. Fonctionnalités détaillées (user stories)

Priorité : **M** = indispensable au MVP · **S** = souhaitable au MVP · **V2** = version suivante.

### 4.1 Découverte des tournois (mobile)

| ID | En tant que… | Je veux… | Afin de… | Prio | Critères d'acceptation |
|---|---|---|---|:-:|---|
| DEC-01 | visiteur | voir la liste des tournois à venir, triés par date et groupés par mois | repérer rapidement les prochains événements | M | Seuls les tournois publiés et non passés apparaissent ; chaque carte affiche affiche/visuel, nom, date, ville, format(s), terrain, badges, statut d'inscription ; chargement paginé (défilement infini). |
| DEC-02 | visiteur | rechercher par texte | retrouver un tournoi précis | M | La recherche porte sur le nom du tournoi, l'organisateur et la ville ; insensible à la casse et aux accents ; résultats en moins d'1 s. |
| DEC-03 | visiteur | filtrer par période, département, format, type, niveau et terrain | ne voir que les tournois qui me correspondent | M | Filtres combinables ; nombre de filtres actifs visible ; bouton « Réinitialiser » ; un tournoi correspond si **au moins un de ses tableaux** correspond aux filtres de format/type/niveau. |
| DEC-04 | visiteur | retrouver mes derniers filtres en rouvrant l'app | ne pas tout ressaisir | S | Filtres mémorisés localement sur le téléphone. |
| DEC-05 | visiteur | consulter les tournois passés | voir l'historique d'un tournoi | M | Onglet ou bascule « Passés », tri antichronologique. |
| DEC-06 | visiteur | voir un état vide clair quand aucun tournoi ne correspond | comprendre et ajuster ma recherche | M | Message explicite + suggestion d'élargir les filtres + lien « Proposer un tournoi ». |
| DEC-07 | visiteur | filtrer par distance et voir une carte | trouver les tournois proches | V2 | — |

### 4.2 Fiche tournoi (mobile)

| ID | En tant que… | Je veux… | Afin de… | Prio | Critères d'acceptation |
|---|---|---|---|:-:|---|
| FIC-01 | visiteur | voir toutes les informations d'un tournoi | décider si je m'inscris | M | Champs définis en section 6 ; tableaux listés avec leurs caractéristiques propres. |
| FIC-02 | visiteur | voir les badges (caritatif, Téléthon, solidaire, spécial, inscriptions bientôt clôturées) | repérer les événements particuliers | M | Badges affichés sur la carte et la fiche ; « Bientôt clôturées » calculé automatiquement (voir RG-08). |
| FIC-03 | visiteur | appuyer sur « S'inscrire » | rejoindre la plateforme d'inscription | M | Ouvre le lien externe dans le navigateur ; si inscription sur place / téléphone, affiche la consigne au lieu du lien ; bouton désactivé si statut « Complet » ou « Fermées » ; le clic est comptabilisé (anonyme). |
| FIC-04 | visiteur | ouvrir l'adresse dans mon application de cartes | m'y rendre | M | Lien vers Google Maps / application de cartes par défaut. |
| FIC-05 | visiteur | voir quand l'information a été vérifiée | juger de sa fiabilité | M | Mention « Vérifié le JJ/MM/AAAA ». |
| FIC-06 | visiteur | voir clairement qu'un tournoi est annulé ou reporté | ne pas me déplacer pour rien | M | Bandeau « Annulé » ou « Reporté au … » en tête de fiche et sur la carte. |
| FIC-07 | visiteur | partager le tournoi | l'envoyer à mes coéquipiers | S | Partage natif (texte + lien). |
| FIC-08 | visiteur | contacter l'organisateur | poser une question | M | E-mail / téléphone / lien réseau social cliquables, si renseignés. |
| FIC-09 | visiteur | accéder à la fiche de l'organisateur | voir ses autres tournois | M | Lien depuis la fiche tournoi. |

### 4.3 Comptes et favoris (mobile)

| ID | En tant que… | Je veux… | Afin de… | Prio | Critères d'acceptation |
|---|---|---|---|:-:|---|
| CPT-01 | visiteur | créer un compte avec e-mail et mot de passe | enregistrer des favoris | M | Mot de passe ≥ 10 caractères ; e-mail unique ; acceptation de la politique de confidentialité ; e-mail de vérification envoyé. |
| CPT-02 | utilisateur | me connecter / me déconnecter | accéder à mes favoris | M | Session conservée sur le téléphone (renouvellement automatique) ; déconnexion possible. |
| CPT-03 | utilisateur | réinitialiser mon mot de passe | récupérer mon compte | M | Lien à usage unique valable 1 h envoyé par e-mail. |
| CPT-04 | utilisateur | supprimer mon compte depuis l'application | exercer mon droit RGPD | M | Suppression définitive du compte et des favoris ; confirmation demandée (exigence Google Play / App Store). |
| CPT-05 | utilisateur | modifier mon pseudo et mon département préféré | personnaliser l'app | S | Le département préféré pré-remplit le filtre par défaut. |
| FAV-01 | utilisateur | ajouter / retirer un tournoi de mes favoris | le retrouver facilement | M | Icône cœur sur la carte et la fiche ; action instantanée (mise à jour optimiste). |
| FAV-02 | visiteur | être invité à me connecter quand j'appuie sur le cœur | comprendre l'intérêt du compte | M | Écran de connexion, puis retour au tournoi avec le favori ajouté. |
| FAV-03 | utilisateur | consulter « Mes tournois » (à venir / passés) | suivre mes événements | M | Les tournois annulés restent visibles avec leur bandeau. |
| CPT-06 | utilisateur | me connecter avec Google ou Apple | aller plus vite | V2 | — |
| NOT-01 | utilisateur | recevoir des notifications | ne rien rater | V2 | — |

### 4.4 Contribution (mobile, sans compte)

| ID | En tant que… | Je veux… | Afin de… | Prio | Critères d'acceptation |
|---|---|---|---|:-:|---|
| CTB-01 | visiteur ou organisateur | proposer un tournoi via un formulaire simple | le faire apparaître dans l'app | M | Champs obligatoires réduits (nom, date, ville, lien ou source, au moins un format) ; affiche facultative ; e-mail de contact facultatif ; protection anti-spam ; message de confirmation « en attente de validation ». |
| CTB-02 | visiteur | signaler une erreur sur une fiche | améliorer la fiabilité | M | Motifs : date erronée, tournoi annulé, lien mort, complet, autre ; commentaire facultatif ; protection anti-spam. |

### 4.5 Back-office administrateur (web)

| ID | En tant qu'… | Je veux… | Afin de… | Prio | Critères d'acceptation |
|---|---|---|---|:-:|---|
| ADM-01 | administrateur | me connecter de façon sécurisée | protéger le back-office | M | Accès réservé au rôle administrateur. |
| ADM-02 | administrateur | créer un tournoi avec un ou plusieurs tableaux | alimenter le catalogue | M | Saisie complète en moins de 2 minutes ; adresse auto-complétée (coordonnées GPS récupérées automatiquement) ; aperçu avant publication. |
| ADM-03 | administrateur | dupliquer l'édition précédente d'une série | republier un tournoi récurrent en 30 s | M | Copie tous les champs sauf dates, statut et lien d'inscription ; rattachée à la même série. |
| ADM-04 | administrateur | modifier, publier, dépublier, annuler, reporter, archiver un tournoi | tenir le catalogue à jour | M | Chaque modification met à jour la date de vérification ; historique des modifications conservé. |
| ADM-05 | administrateur | uploader une affiche | illustrer le tournoi | M | JPEG/PNG/WebP, ≤ 10 Mo ; redimensionnement automatique ; visuel générique par défaut selon le terrain. |
| ADM-06 | administrateur | gérer les organisateurs | rattacher les tournois | M | Nom, type, logo, description, ville, contacts, liens. |
| ADM-07 | administrateur | traiter la file des propositions | modérer les contributions | M | Liste des propositions en attente ; ouvrir, compléter, valider (→ publié) ou refuser avec motif ; alerte si doublon probable. |
| ADM-08 | administrateur | traiter la file des signalements | corriger les erreurs | M | Liste des signalements ouverts par tournoi ; marquer « traité » ou « rejeté ». |
| ADM-09 | administrateur | voir les statistiques par tournoi | mesurer l'utilité de l'app | S | Nombre de vues de fiche et de clics « S'inscrire ». |
| ADM-10 | administrateur | voir un tableau de bord | prioriser mon travail | S | Nombre de propositions en attente, signalements ouverts, tournois des 30 prochains jours, tournois non vérifiés depuis plus de 30 jours. |
| ADM-11 | administrateur | être aidé par une IA pour pré-remplir un tournoi depuis un texte ou une affiche | gagner du temps | V2 | — |

---

## 5. Règles métier

| ID | Règle |
|---|---|
| **RG-01 — Série et édition** | Un tournoi récurrent est une **série** (ex. « Tournoi de la Plage de Carnac »). Chaque année est une **édition** de cette série, avec ses dates propres. Un tournoi ponctuel est une série à une seule édition (transparent pour l'utilisateur). Dans l'app, « un tournoi » désigne une édition. |
| **RG-02 — Tableaux** | Une édition contient **un ou plusieurs tableaux**. Chaque tableau a : format (2x2, 3x3, 4x4, 6x6, autre), type (masculin, féminin, mixte, libre), niveau(x), terrain, prix par équipe ou par joueur, nombre maximum d'équipes, horaire facultatif. Une édition simple n'a qu'un tableau. |
| **RG-03 — Cycle de vie (publication)** | `brouillon` → `en_attente` → `publié` ou `refusé` ; `publié` → `archivé`. Seuls les tournois `publié` sont visibles dans l'app. Un refus est accompagné d'un motif. |
| **RG-04 — Statut de l'événement** | Indépendant de la publication : `prévu`, `reporté` (avec nouvelle date si connue), `annulé`. Un tournoi annulé ou reporté reste visible avec un bandeau ; il n'est jamais supprimé s'il a été publié. |
| **RG-05 — Statut des inscriptions** | Saisi manuellement : `pas_encore_ouvertes`, `ouvertes`, `complet`, `fermées`. Mode d'inscription : `lien_externe` (URL obligatoire), `sur_place`, `téléphone_ou_email`. |
| **RG-06 — Tournoi passé** | Une édition est « passée » le lendemain de sa date de fin. Elle bascule automatiquement dans l'historique ; elle reste consultable mais le bouton « S'inscrire » disparaît. |
| **RG-07 — Date de vérification** | Chaque création, modification ou confirmation par l'administrateur met à jour la date « Vérifié le ». Le tableau de bord signale les tournois à venir non vérifiés depuis plus de 30 jours. |
| **RG-08 — Badge « Bientôt clôturées »** | Affiché automatiquement si les inscriptions sont `ouvertes` et que la date limite d'inscription est dans 7 jours ou moins. Les autres badges (caritatif, Téléthon, solidaire, spécial) sont attribués manuellement. |
| **RG-09 — Propositions** | Toute proposition arrive en `en_attente`, sans exception, quelle que soit sa source. L'administrateur peut la compléter avant validation. |
| **RG-10 — Doublons** | À la création ou à la validation, le système signale un doublon probable si une édition existe déjà avec une date proche (± 3 jours) dans la même ville, ou avec un nom similaire. La décision reste humaine. |
| **RG-11 — Signalements** | Un signalement n'entraîne aucune modification automatique de la fiche. Statuts : `ouvert`, `traité`, `rejeté`. |
| **RG-12 — Visuels** | Une affiche n'est publiée que si elle a été fournie par l'organisateur (formulaire, e-mail) ou est libre de droits. À défaut, un visuel générique selon le terrain (salle, extérieur, sable) est affiché. |
| **RG-13 — Organisateur** | Tout tournoi est rattaché à un organisateur. Types : club, association, collectivité / comité des fêtes, entreprise / bar, particulier, autre. |
| **RG-14 — Zone géographique** | Toute édition a une adresse géocodée (latitude / longitude) rattachée à une commune, un département et une région, même si la carte et la distance n'arrivent qu'en V2. |
| **RG-15 — Suppression de compte** | La suppression d'un compte efface définitivement l'utilisateur et ses favoris. Les propositions et signalements anonymes ne sont pas concernés. |
| **RG-16 — Statistiques** | Vues de fiche et clics « S'inscrire » sont comptés de façon anonyme (aucune donnée personnelle, aucun cookie, aucun identifiant publicitaire). |

---

## 6. Contenu d'une fiche tournoi

### 6.1 Édition (niveau tournoi)

| Champ | Obligatoire | Remarques |
|---|:-:|---|
| Nom | ✅ | |
| Organisateur | ✅ | Lien vers la fiche organisateur |
| Date de début | ✅ | |
| Date de fin | ❌ | Par défaut = date de début (tournois sur plusieurs jours possibles) |
| Heure de début / d'accueil | ❌ | |
| Lieu : nom du site | ❌ | Ex. « Plage de la Grande Plage », « Gymnase Jean Moulin » |
| Adresse + commune | ✅ | Géocodée automatiquement (latitude / longitude) |
| Affiche / photo | ❌ | Visuel générique sinon (RG-12) |
| Description | ❌ | Texte libre (programme, restauration, ambiance…) |
| Règlement | ❌ | Texte ou lien |
| Mode d'inscription | ✅ | Lien externe / sur place / téléphone-e-mail |
| Lien d'inscription | ✅ si lien externe | HelloAsso, Google Forms, site du club… (URL https validée) |
| Date limite d'inscription | ❌ | Sert au badge « Bientôt clôturées » |
| Statut des inscriptions | ✅ | RG-05 |
| Statut de l'événement | ✅ | RG-04 (défaut : prévu) |
| Badges | ❌ | Caritatif, Téléthon, solidaire, spécial |
| Contacts | ❌ | E-mail, téléphone, lien réseau social |
| Date de vérification | ✅ | Automatique |
| Source de l'information | ❌ | Interne : d'où vient l'info (lien du post, e-mail…) |

### 6.2 Tableau (au moins un par édition)

| Champ | Obligatoire | Remarques |
|---|:-:|---|
| Format | ✅ | 2x2, 3x3, 4x4, 6x6, autre |
| Type | ✅ | Masculin, féminin, mixte, libre |
| Niveau(x) | ✅ | Un ou plusieurs parmi : débutant, loisir, intermédiaire, confirmé, compétition |
| Terrain | ✅ | Intérieur, extérieur, sable |
| Joueurs par équipe | ✅ | Déduit du format, modifiable (ex. 4x4 avec remplaçants : 4 à 6) |
| Prix d'inscription | ❌ | Montant + unité (par équipe / par joueur) ; « gratuit » possible ; vide = non communiqué |
| Nombre maximum d'équipes | ❌ | |
| Horaire du tableau | ❌ | Ex. « matin », « 14 h » |
| Conditions particulières | ❌ | Ex. « au moins 2 filles sur le terrain » |

---

## 7. Modèle de données conceptuel

> Vue d'ensemble validant les besoins fonctionnels. Le diagramme entité-association détaillé, les contraintes, les index et les scripts SQL seront produits en **phase 2**.

| Entité | Rôle | Relations principales |
|---|---|---|
| **users** | Comptes (utilisateurs, administrateurs, organisateurs V2) | 1 rôle ; N favoris |
| **roles** | user, organizer, admin | |
| **regions / departments / cities** | Référentiel géographique (données officielles INSEE) | région 1–N départements 1–N communes |
| **organizers** | Clubs et autres organisateurs | N séries ; 1 commune ; 0–1 logo ; (V2) N utilisateurs gestionnaires |
| **tournament_series** | Tournoi récurrent | 1 organisateur ; N éditions |
| **tournaments** (éditions) | Un tournoi daté | 1 série ; 1 lieu ; N tableaux ; N tags ; 0–1 affiche |
| **venues** | Lieu physique (adresse, coordonnées GPS) | 1 commune ; réutilisable entre éditions |
| **tournament_divisions** | Tableaux d'une édition | 1 édition ; 1 format ; 1 type ; N niveaux ; 1 terrain |
| **référentiels** | Formats, types, niveaux, terrains | |
| **tags** | Badges manuels (caritatif, Téléthon…) | N–N avec éditions |
| **media** | Fichiers stockés (affiches, logos) | Référencés par éditions et organisateurs |
| **favorites** | Favoris | utilisateur N–N édition |
| **submissions** | Propositions de tournoi | Données brutes + statut ; liée à l'édition créée si validée |
| **reports** | Signalements | 1 édition |
| **audit_log** | Historique des modifications du back-office | |
| **tournament_stats** | Compteurs anonymes vues / clics par jour | 1 édition |
| **registrations** | *Non développé* — réservé pour l'inscription interne future | |

---

## 8. Navigation et écrans

> Les wireframes détaillés seront produits et validés en **phase 2**, avant tout développement d'écran.

### 8.1 Application mobile — barre d'onglets en bas

| Onglet | Écrans |
|---|---|
| **Tournois** (accueil) | Liste à venir / passés · Recherche · Panneau de filtres · Fiche tournoi · Fiche organisateur · Signaler une erreur |
| **Mes tournois** | Favoris à venir / passés (invitation à se connecter si visiteur) |
| **Proposer** | Formulaire de proposition · Confirmation |
| **Profil** | Connexion · Inscription · Mot de passe oublié · Mon compte · Supprimer mon compte · À propos, mentions légales, confidentialité |

### 8.2 Back-office web

Tableau de bord · Tournois (liste, création, édition, duplication) · Organisateurs · Propositions · Signalements · Statistiques.

---

## 9. Identité visuelle

| Élément | Choix |
|---|---|
| Ambiance | **Minimaliste et sportive** : beaucoup d'espace, typographie grasse pour les titres, les affiches des tournois apportent la couleur |
| Couleur d'accent | Orange « ballon » vif (à affiner en phase 2), sur fond clair ou sombre |
| Thème | Clair et sombre, automatique selon le réglage du téléphone |
| Références | Airbnb (cartes, fiches, filtres), Strava (côté sportif), Eventbrite (découverte d'événements) |
| Logo | Pictogramme SVG simple proposé en phase 2, remplaçable |
| Langue | Français ; tous les textes externalisés (traduction future possible) |
| Accessibilité | Contrastes WCAG AA, tailles de texte système respectées, libellés pour lecteurs d'écran, zones tactiles ≥ 44 px |

---

## 10. Alimentation du catalogue

C'est le facteur clé de succès : l'app n'a de valeur que si le catalogue est complet et à jour.

### 10.1 Sources au MVP

| Source | Fonctionnement | Volume attendu |
|---|---|---|
| **Saisie administrateur** | Veille manuelle (Facebook, Instagram, HelloAsso, sites de clubs) puis saisie dans le back-office | Principale au lancement |
| **Duplication d'éditions** | Les tournois récurrents sont republiés chaque année en quelques secondes | Croissante d'année en année |
| **Propositions** | Joueurs et organisateurs proposent des tournois via l'app | Croissante avec l'audience |

**Objectif de lancement : au moins 20 tournois à venir publiés dans la zone pilote** au moment de la mise en ligne.

### 10.2 Collecte automatisée — analyse et décision

| Source | Faisabilité | Décision |
|---|---|---|
| Facebook / Instagram | Scraping interdit par les conditions d'utilisation de Meta ; les API ne donnent pas accès aux publications de pages tierces | **Exclu** |
| HelloAsso | API officielle orientée « une association accède à ses propres données » ; pas d'accès documenté à l'annuaire public | **À vérifier en phase 5** (partenariat possible) |
| Sites de clubs | Légalement possible au cas par cas (respect des CGU et du robots.txt), mais structures hétérogènes : effort disproportionné | **Non retenu au MVP** |
| Texte ou affiche fourni par l'administrateur | L'administrateur colle un texte ou une photo ; une IA pré-remplit le formulaire ; l'administrateur valide | **Retenu pour la phase 5 / V2** |

### 10.3 Processus de validation

1. **Réception** : proposition, saisie administrateur ou pré-remplissage IA (V2).
2. **Identification** : rattachement à un organisateur et à une série existante (ou création).
3. **Extraction / complétion** des données (formulaire structuré).
4. **Détection des doublons** (RG-10).
5. **Vérification** par l'administrateur (lien d'inscription valide, cohérence des dates).
6. **Validation** → `publié` (ou refus avec motif).
7. **Maintien à jour** : signalements, statuts d'inscription, date de vérification, alerte des tournois non vérifiés.

---

## 11. Exigences non fonctionnelles

| Domaine | Exigence |
|---|---|
| **Performance** | Liste des tournois affichée en moins de 2 s en 4G ; réponses API < 300 ms (95e percentile) ; images redimensionnées et compressées (WebP). |
| **Compatibilité** | Android 8 (API 26) et plus ; iOS 15 et plus (compilable, publication en V2) ; back-office sur navigateurs récents (Chrome, Firefox, Edge). |
| **Sécurité** | HTTPS partout ; mots de passe hachés (Argon2id) ; jetons d'accès courts + jetons de renouvellement révocables ; contrôle des rôles sur chaque route ; validation de toutes les entrées ; limitation du débit (connexion, propositions, signalements) ; protection anti-spam des formulaires ; secrets dans Secret Manager, jamais dans le code ; dépendances surveillées. |
| **RGPD** | Données personnelles minimales (e-mail, pseudo, département préféré facultatif) ; politique de confidentialité et mentions légales ; suppression de compte dans l'app ; aucun traçage publicitaire ; hébergement des données dans l'Union européenne. |
| **Disponibilité** | Pas d'engagement de disponibilité (projet personnel) ; sauvegarde quotidienne de la base de données avec rétention de 7 jours minimum. |
| **Maintenabilité** | Code structuré en couches, testé (tests unitaires et d'intégration du backend, tests des composants clés côté mobile), documenté (README, OpenAPI) ; CI exécutant lint et tests à chaque push. |
| **Observabilité** | Journaux structurés (JSON) ; suivi des erreurs ; alerte en cas de taux d'erreur élevé. |
| **Évolutivité** | Monolithe modulaire (pas de microservices) ; API versionnée (`/v1`) ; modèle de données prêt pour l'inscription interne, les organisateurs, les notifications et d'autres régions. |
| **Accessibilité** | Voir section 9. |

---

## 12. Stack technique retenue

| Brique | Choix | Justification courte |
|---|---|---|
| Application mobile | **React Native + Expo (TypeScript)** | Une base de code Android + iOS ; build iOS sans Mac (EAS) ; mises à jour à distance ; même langage que le back-office ; client API généré automatiquement. Flutter écarté : excellent mais langage spécifique et back-office web moins adapté. |
| Back-office web | **React + Vite (TypeScript)** | Mêmes compétences et types partagés avec le mobile. |
| Backend | **Go — API REST, monolithe en couches** (handler / service / repository) | Choix de référence du porteur ; performant, simple à déployer sur Cloud Run. Détails (routeur, accès base, migrations, auth) arrêtés en phase 2. |
| Base de données | **PostgreSQL** | Choix de référence ; robuste ; recherche plein texte et extensions géographiques disponibles. |
| Documentation API | **OpenAPI (Swagger)** | Contrat entre backend et clients ; génération du client TypeScript. |
| Géocodage | **API Adresse (Base Adresse Nationale, data.gouv.fr)** | Gratuite, officielle, très fiable pour la France. |
| E-mails transactionnels | Fournisseur avec offre gratuite (ex. Brevo) — à confirmer en phase 2 | Vérification d'e-mail et mot de passe oublié. |
| Outils de développement | Windows + VS Code + Docker Desktop ; tests sur téléphone Android via Expo Go | Matériel du porteur. |

---

## 13. Infrastructure et budget

### 13.1 Architecture cible du MVP

| Besoin | Service | Coût estimé |
|---|---|---|
| Backend Go | **Cloud Run** (région Europe) | ~0 € (offre gratuite) |
| Base de données | **PostgreSQL managé : Neon ou Supabase (offre gratuite, région UE)** au MVP, migration vers **Cloud SQL** quand le projet le justifie | 0 € (Cloud SQL : ~10-15 €/mois) |
| Affiches et logos | **Cloud Storage** | ~0 € |
| Back-office web | Hébergement statique (Cloud Storage + CDN ou Firebase Hosting) | ~0 € |
| CI/CD | **Cloud Build** ou GitHub Actions | ~0 € |
| Secrets | **Secret Manager** | ~0 € |
| Journaux et monitoring | **Cloud Logging / Monitoring** | ~0 € |
| Builds mobiles | **Expo EAS** (offre gratuite) | 0 € |
| Nom de domaine | Registraire au choix | ~10-15 €/an |
| Google Play | Compte développeur | 25 $ (une fois) |
| Apple App Store | Compte développeur (V2) | 99 $/an |

**Budget cible : moins de 10 €/mois d'hébergement**, hors frais ponctuels des stores et du domaine.

> **Décision** : la base de données sur Neon/Supabase (≈ 0 €) est retenue pour le MVP ; Cloud SQL (≈ 10-15 €/mois) reste possible plus tard sans modification de code.

---

## 14. Indicateurs de succès

| Indicateur | Objectif à 3 mois après le lancement |
|---|---|
| Tournois à venir publiés (zone pilote) | ≥ 20 au lancement, ≥ 40 sur la saison |
| Utilisateurs actifs mensuels | 100 |
| Clics « S'inscrire » | 200 cumulés |
| Propositions reçues de la communauté | 5 |
| Délai moyen de traitement d'un signalement | < 48 h |
| Note sur Google Play | ≥ 4,3 |

---

## 15. Roadmap

Chaque phase se termine par une présentation des résultats et une **validation explicite** avant de passer à la suivante.

| Phase | Objectifs | Principales tâches | Technologies | Livrables | Critères de fin |
|---|---|---|---|---|---|
| **1. Cadrage** ✅ | Définir le produit | Entretien, périmètre, stack | — | Ce cahier des charges | Document validé |
| **2. Conception** | Concevoir avant de coder | Architecture logicielle, diagramme entité-association, modèle PostgreSQL, contrat OpenAPI, navigation, wireframes, charte graphique | Mermaid, OpenAPI, maquettes | Dossier de conception, scripts SQL commentés, spécification OpenAPI, wireframes validés | Modèle, API et wireframes validés |
| **3. Backend** | API fonctionnelle et testée | Init projet Go, Docker Compose PostgreSQL, migrations, référentiels géographiques, endpoints publics / utilisateur / admin, authentification, upload, tests | Go, PostgreSQL, Docker | API exécutable en local, documentation Swagger, tests au vert, CI | Tous les endpoints MVP testés ; couverture des services ≥ 70 % |
| **4. Application mobile** | App utilisable sur téléphone | Init Expo, navigation, thème, écrans, client API, auth, filtres, favoris, proposition, signalement | React Native, Expo, TypeScript | App testable via Expo Go | Toutes les user stories mobiles M validées sur Android |
| **5. Back-office et collecte** | Outil d'alimentation efficace | Back-office web, modération, duplication, statistiques, étude HelloAsso et pré-remplissage IA | React, Vite, TypeScript | Back-office opérationnel, ≥ 20 tournois saisis | Saisie d'un tournoi < 2 min ; files de modération fonctionnelles |
| **6. Infrastructure et déploiement** | Mise en production | Projet GCP, Cloud Run, base managée, Cloud Storage, Secret Manager, CI/CD, domaine, monitoring, sauvegardes | GCP, Docker, CI/CD | Environnement de production documenté | Déploiement automatique à chaque merge ; restauration de sauvegarde testée |
| **7. Tests et lancement** | Publication de la v1.0 | Tests fonctionnels, de charge légère, de sécurité, bêta fermée (amis joueurs), corrections, fiche Play Store, mentions légales | EAS Build / Submit | App publiée sur Google Play | v1.0 en ligne avant mai-juin 2027 |

### Calendrier indicatif (hypothèse : 6 à 8 h par semaine)

| Période | Phase |
|---|---|
| Novembre 2026 | 1 — Cadrage · 2 — Conception |
| Décembre 2026 – janvier 2027 | 3 — Backend |
| Février – mars 2027 | 4 — Application mobile |
| Mars – avril 2027 | 5 — Back-office · saisie du catalogue |
| Avril 2027 | 6 — Infrastructure (mise en place progressive dès la phase 3) |
| Mai 2027 | 7 — Bêta, corrections, publication |

---

## 16. Hypothèses et points ouverts

| # | Sujet | Hypothèse retenue | À confirmer |
|---|---|---|---|
| H1 | Temps disponible | 6 à 8 h par semaine | ✅ Confirmé |
| H2 | Base de données | Neon ou Supabase (gratuit) au MVP, Cloud SQL plus tard | ✅ Confirmé |
| H3 | Loire-Atlantique (44) | **Incluse** dans la zone pilote | ✅ Confirmé |
| H4 | Nom de l'application | « VolleySpot » provisoire | ✅ Confirmé — nom définitif à choisir avant la phase 7 |
| H5 | Niveau du porteur | Débutant en TypeScript / React ; notions de Go | ✅ Confirmé |

---

## 17. Glossaire

| Terme | Définition |
|---|---|
| **MVP** | *Minimum Viable Product* : première version publiable, limitée à l'essentiel. |
| **Série** | Tournoi récurrent, identique d'une année sur l'autre. |
| **Édition** | Occurrence datée d'une série (ce que l'utilisateur appelle « un tournoi »). |
| **Tableau** | Compétition au sein d'une édition (ex. « 4x4 mixte loisir »). |
| **Organisateur** | Club, association ou toute entité qui organise un tournoi. |
| **Proposition** | Tournoi soumis par un tiers, en attente de validation. |
| **Signalement** | Alerte d'un utilisateur sur une information erronée. |
| **Back-office** | Interface web d'administration. |
| **API REST** | Interface par laquelle l'app et le back-office communiquent avec le serveur. |
| **OpenAPI / Swagger** | Format standard de description d'une API. |
| **Expo / EAS** | Outils de développement, de compilation et de publication d'apps React Native. |
