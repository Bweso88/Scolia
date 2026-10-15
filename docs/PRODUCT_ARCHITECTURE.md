# Scolia — Le cahier de liaison numérique de l'école

Document d'architecture produit et technique. Rédigé avant tout code, conformément
à la démarche demandée. Sert de référence pendant toute l'implémentation : toute
décision qui s'en écarte doit être justifiée et reportée ici.

Positionnement commercial retenu : on ne vend pas « une application scolaire »,
on vend **le cahier de liaison numérique de l'école**, en marque blanche, avec un
abonnement annuel par établissement. La plateforme (Scolia) reste discrète
derrière l'identité visuelle de chaque école (« Powered by Scolia »).

---

## 1. Vision complète du produit

Scolia est une plateforme **SaaS multi-écoles** qui remplace le cahier de
correspondance papier par une expérience mobile simple pour les parents,
et par un back-office complet pour les établissements.

Principe de marque blanche : une école qui souscrit obtient une **instance
personnalisée** (logo, couleurs, coordonnées) à l'intérieur d'une **seule
application mobile Scolia**. Le parent télécharge une seule app ; après
connexion, il ne voit que l'univers de son/ses école(s). Il n'y a pas
d'application par école à publier sur les stores — c'est un choix
d'architecture volontaire (voir §5) qui rend le SaaS scalable : ajouter la
1000ᵉ école ne demande ni nouveau build mobile, ni nouvelle publication
store, seulement une nouvelle ligne de configuration.

Promesse au parent : *« Tout ce que vous devez savoir sur la vie scolaire
de votre enfant, directement dans votre téléphone. »*

Promesse à l'école : *« Votre propre application de communication, prête en
quelques jours, sans rien développer. »*

Le produit doit rester utilisable par un parent peu à l'aise avec le
numérique : peu d'écrans, pas de jargon, notifications qui font le travail
de rappel à la place de l'utilisateur.

---

## 2. Personas utilisateurs

| Persona | Contexte | Besoins clés | Points de friction à éviter |
|---|---|---|---|
| **Parent (Mariam, 38 ans)** | 2 enfants dans la même école, smartphone Android d'entrée de gamme, peu de temps | Savoir vite si tout va bien, être alertée en cas de problème, ne pas rater un devoir ou une réunion | Trop d'écrans, trop de notifications non filtrées, appli lourde/lente |
| **Parent multi-écoles (Jean, 45 ans)** | Un enfant dans une école A, un autre dans une école B | Changer d'enfant/école sans se reconnecter, ne pas confondre les univers des deux écoles | Mélange visuel entre les deux écoles, données croisées |
| **Enseignant (Mme Koffi)** | Donne cours dans plusieurs classes, veut publier vite un devoir ou une remarque | Publication rapide depuis mobile ou web, pas de double saisie, cadre clair sur qui elle peut contacter | Devoir remplir un formulaire complexe pour un besoin quotidien |
| **Administration / Direction (M. Diallo, censeur)** | Pilote la vie scolaire de l'établissement, doit produire des annonces, gérer absences, arbitrer les demandes | Vue d'ensemble (tableau de bord), diffusion ciblée (classe, groupe, individuel), traçabilité | Devoir jongler entre plusieurs outils (Excel, WhatsApp, papier) |
| **Fondateur d'école privée (cliente SaaS)** | Décide de l'achat de l'abonnement | Vitrine moderne pour attirer les parents, coût prévisible, mise en place rapide, support | Peur de la dépendance à un outil qui « expose » les données de son école à la concurrence |
| **Super Admin plateforme (équipe Scolia)** | Gère l'ensemble des écoles clientes | Provisionner une école en quelques minutes, superviser l'usage, facturer, supporter | Ne doit jamais avoir un accès qui inquiète les écoles sur la confidentialité |

---

## 3. Liste des fonctionnalités (vue complète)

1. Gestion multi-tenant des écoles (provisioning, configuration, marque blanche)
2. Gestion des élèves, classes, années scolaires
3. Gestion des parents (y compris multi-enfants / multi-écoles)
4. Gestion des enseignants et de leurs affectations (classes × matières)
5. Authentification et gestion des sessions/appareils
6. Tableau de bord parent (par enfant sélectionné)
7. Cahier de texte / devoirs (par matière, par jour, pièces jointes, statut)
8. Comportement (observations positives/négatives, historique)
9. Absences et retards (saisie école, justification parent)
10. Messagerie école ↔ parents (individuelle, collective, avec règles d'autorisation)
11. Annonces (générales, par classe, par groupe, par parent)
12. Emploi du temps / programme / calendrier académique
13. Notes et bulletins (module activable/désactivable par école)
14. Documents (bulletins, circulaires, règlement, autorisations)
15. Notifications push configurables
16. Back-office web école (gestion de toutes les entités ci-dessus)
17. Tableau de bord école (KPIs d'usage)
18. Gestion des rôles et permissions
19. Personnalisation / marque blanche par école
20. Modèle SaaS (plans, quotas, facturation) piloté depuis un back-office plateforme
21. Sécurité transverse (audit, sessions, chiffrement, isolation des tenants)
22. (V2/V3) IA : résumés, assistant, détection d'élèves à accompagner, chatbot

---

## 4. Fonctionnalités MVP vs V2 vs V3

### MVP (commercialisable, un seul cycle de développement)
Gestion écoles · élèves · parents · enseignants · authentification ·
tableau de bord parent · devoirs/cahier de texte · communication (messagerie +
règles d'autorisation) · annonces · absences · comportement · emploi du temps ·
notifications push · administration web · personnalisation par école (logo,
couleurs, coordonnées) · fondations multi-tenant + rôles/permissions +
sécurité de base (elles ne sont pas optionnelles : sans elles le MVP n'est pas
vendable à une deuxième école en toute sécurité).

Modules activables/désactivables par école dès le MVP (flag simple, pas de
développement conditionnel dans le code) : **Notes/bulletins** peut être livré
en V1.1 mais la table `subscription_modules` qui pilote l'activation existe
dès le MVP pour ne pas avoir à la retrofit.

### V2
Notes et bulletins complets (moyennes, coefficients, classement, export PDF) ·
justification d'absence par le parent avec pièce jointe · documents
administratifs (dépôt/consultation) · statistiques d'usage avancées côté
back-office plateforme · paiements/frais de scolarité · export de données
école (portabilité) · gestion fine des permissions par rôle personnalisé.

### V3
IA : résumé automatique des informations importantes, assistant scolaire,
analyse des résultats, détection (avec validation humaine obligatoire) des
élèves nécessitant une attention particulière, génération assistée de
comptes rendus, chatbot école-parent · canaux SMS/WhatsApp · web app parent ·
signature électronique de documents (autorisations de sortie, etc.).

**Risque signalé** : ne pas céder à la tentation d'ajouter les notes
complètes ou l'IA dans le MVP « parce que c'est facile » — chaque module
supplémentaire multiplie les cas de test de l'isolation multi-tenant et
retarde la mise sur le marché sans laquelle il n'y a pas de retour terrain.

---

## 5. Architecture technique

```
┌─────────────────────┐        ┌─────────────────────┐
│   App mobile unique  │        │   Back-office web    │
│   (Flutter, iOS/And.)│        │  (Laravel + Livewire) │
│   Parent + Enseignant│        │  École + Super Admin  │
└──────────┬───────────┘        └──────────┬───────────┘
           │ REST/JSON (Sanctum)            │ Session web (Sanctum SPA / Livewire)
           ▼                                ▼
     ┌─────────────────────────────────────────────┐
     │           API Laravel (api/v1/*)             │
     │  Middleware: auth ▸ resolve-tenant ▸ policy  │
     ├───────────────────────────────────────────────┤
     │  Domaines : Ecoles, Utilisateurs, Eleves,     │
     │  Devoirs, Comportement, Absences, Messagerie, │
     │  Annonces, EmploiDuTemps, Notes, Documents,   │
     │  Notifications, Abonnements                   │
     ├───────────────────────────────────────────────┤
     │   Queue (jobs: notifications, exports, mail)  │
     └───────────────────┬───────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
        MySQL (1 base,          Stockage fichiers
        multi-tenant par        (S3-compatible ou
        tenant_id + policies)   disque local en dev)
                          │
                          ▼
                Firebase Cloud Messaging
                (notifications push)
```

**Choix structurants et justification**

- **Laravel (PHP) + MySQL** : demandé, et cohérent avec un budget de
  lancement limité — écosystème mature (Sanctum, Horizon, Nova/Filament,
  spatie/laravel-permission), hébergement bon marché, recrutement facile en
  Afrique francophone.
- **Une seule application Flutter** pour tous les parents/enseignants de
  toutes les écoles (pas une app par école). C'est ce qui rend le modèle
  SaaS scalable : publier et maintenir une app par école serait
  intenable dès la 5ᵉ école (délais Apple/Google, versions à synchroniser).
  L'identité visuelle de l'école est chargée **au runtime** depuis l'API
  (voir §16), pas compilée en dur.
- **API REST versionnée** (`/api/v1/...`) consommée à la fois par le mobile
  et par un futur client web parent (V3) : un seul contrat d'API à
  maintenir.
- **Back-office école** en Laravel + Livewire plutôt que React : équipe
  PHP existante, pas besoin d'un second stack front pour un back-office
  interne (formulaires, tableaux, filtres). Un futur portail « vitrine »
  public pourrait justifier du React, mais ce n'est pas le cas ici.
- **File d'attente (queue)** dès le MVP pour tout ce qui est notification /
  envoi de masse : un envoi à 300 parents ne doit jamais bloquer une requête
  HTTP ni faire tomber le serveur.
- **Firebase Cloud Messaging** pour push Android/iOS, choix demandé et
  standard, gratuit à l'échelle visée.

---

## 6. Architecture multi-tenant

**Modèle retenu : base de données unique, schéma partagé, isolation par
`tenant_id` (« shared database, shared schema »)**, plutôt qu'une base par
école.

Justification (à revalider explicitement au-delà de ~300-500 écoles ou en
cas d'exigence contractuelle d'isolation physique par une école) :
- Coût d'infrastructure et de maintenance minimal pour démarrer à 1 école et
  scaler à 100-1000 : une seule base à sauvegarder, monitorer, migrer.
- Les migrations de schéma (nouvelle fonctionnalité) s'appliquent une fois,
  pas une fois par école.
- L'isolation logique est suffisante si elle est appliquée **au niveau du
  code, systématiquement, jamais au cas par cas** (voir ci-dessous).

Mécanisme d'isolation :
1. Table pivot `tenants` (= écoles) au niveau plateforme.
2. **Toutes** les tables métier portent une colonne `tenant_id` (non
   nullable, `foreign key` vers `tenants.id`, indexée en tête de tous les
   index composites).
3. **Global Scope Eloquent obligatoire** (`BelongsToTenant` trait +
   `TenantScope`) appliqué automatiquement à tous les modèles métier : aucune
   requête ne peut « oublier » le filtre par tenant. Le `tenant_id` courant
   est résolu une fois par requête HTTP (middleware `ResolveTenant`) à partir
   du tenant associé à l'utilisateur authentifié (un `User` appartient à un
   seul tenant sauf le Super Admin plateforme qui n'appartient à aucun et
   passe par un guard séparé).
4. Un utilisateur parent avec des enfants dans **plusieurs écoles** n'est
   pas un cas particulier de l'isolation : il possède **un compte
   `User` distinct par tenant** (même email possible, `unique(email,
   tenant_id)`), reliés entre eux par un `parent_identity_id` commun
   (table `parent_identities`) qui permet à l'app de proposer un
   sélecteur « École A / École B » sans jamais faire une requête cross-tenant
   sur les données scolaires.
5. Les policies Laravel (`Gate`) vérifient systématiquement
   `$user->tenant_id === $model->tenant_id` en plus du rôle — filet de
   sécurité en cas d'oubli du scope global.
6. Tests automatisés dédiés : pour chaque endpoint métier, un test vérifie
   qu'un utilisateur de l'école A reçoit 403/404 sur une ressource de
   l'école B. Ce test est un pré-requis de mise en production, pas une
   option.
7. Fichiers (documents, pièces jointes) stockés sous un préfixe
   `tenants/{tenant_id}/...` sur le disque de stockage, jamais accessibles
   par URL directe non signée.

Ajouter une école = une ligne dans `tenants` + sa configuration
d'apparence + son abonnement : **aucune modification de code, aucun
déploiement**.

Risque explicitement signalé : le principal risque de cette architecture
n'est pas technique mais humain — un développeur qui écrit une requête
Eloquent en contournant le scope global (`withoutGlobalScope`) sans
justification documentée. Règle d'équipe : `withoutGlobalScope` interdit en
dehors du contexte Super Admin plateforme, revue de code obligatoire dessus.

---

## 7. Schéma complet de la base MySQL (MVP)

Convention : `id` = bigint auto-increment sauf mention contraire,
`timestamps` = `created_at`/`updated_at`, `soft_deletes` où la suppression
doit rester auditable.

### Plateforme (hors tenant)

```
tenants
  id, name, slug (unique), status (trial|active|suspended|cancelled),
  school_year_start_month, timezone, locale, created_at, updated_at

tenant_settings                -- personnalisation / marque blanche (§16)
  id, tenant_id (FK unique), display_name, logo_path, cover_image_path,
  primary_color, secondary_color, phone, email, address, website,
  current_school_year_id (FK school_years, nullable), timestamps

plans                          -- catalogue commercial, piloté back-office
  id, code (starter|standard|premium|...), name, max_students,
  price_amount, price_currency, billing_period (monthly|yearly),
  is_active, sort_order, timestamps

plan_features                  -- quelles fonctionnalités par plan
  id, plan_id (FK), feature_key, is_enabled, limit_value (nullable)

subscriptions
  id, tenant_id (FK), plan_id (FK), status (trialing|active|past_due|
  canceled), current_period_start, current_period_end, students_count_cache,
  timestamps

subscription_modules           -- activation/désactivation de module par école
  id, tenant_id (FK), module_key (notes|documents|...), is_enabled, timestamps

platform_admins                -- Super Admin plateforme, hors tenant
  id, name, email, password, timestamps

audit_logs
  id, tenant_id (nullable, FK), actor_type, actor_id, action,
  subject_type, subject_id, ip_address, user_agent, meta (json),
  created_at
```

### Identité & rôles (par tenant)

```
users
  id, tenant_id (FK), parent_identity_id (FK nullable), name, email,
  phone, password, avatar_path, locale, is_active, last_login_at,
  email_verified_at, timestamps
  unique(tenant_id, email)

parent_identities               -- relie les comptes d'un même parent multi-écoles
  id, full_name, canonical_email, canonical_phone, timestamps

roles / permissions / model_has_roles / role_has_permissions
  -- fournies par spatie/laravel-permission (teams activé, team = tenant_id)

personal_access_tokens          -- Sanctum (tokens API mobile), avec
  device_name, last_used_at, expires_at pour permettre la révocation par
  appareil (§19)
```

### Structure scolaire

```
school_years
  id, tenant_id (FK), label (ex: "2026-2027"), start_date, end_date,
  is_current, timestamps

school_classes                  -- "classe" (nom réservé en PHP -> school_classes)
  id, tenant_id (FK), school_year_id (FK), name, level, homeroom_teacher_id
  (FK teachers, nullable), timestamps

subjects
  id, tenant_id (FK), name, timestamps

teachers
  id, tenant_id (FK), user_id (FK users), employee_number, timestamps

teacher_assignments              -- enseignant × classe × matière
  id, tenant_id (FK), teacher_id (FK), school_class_id (FK), subject_id (FK),
  timestamps

students
  id, tenant_id (FK), school_class_id (FK), first_name, last_name,
  birth_date, gender, photo_path, enrollment_number, status (active|
  transferred|graduated), timestamps

student_guardians                -- lien élève ↔ parent (+ type: père/mère/tuteur)
  id, tenant_id (FK), student_id (FK), user_id (FK users), relationship_type,
  is_primary_contact, timestamps
```

### Cahier de texte / devoirs

```
lessons                          -- séance de cours (contenu)
  id, tenant_id (FK), school_class_id (FK), subject_id (FK), teacher_id (FK),
  date, content, timestamps

homeworks
  id, tenant_id (FK), lesson_id (FK nullable), school_class_id (FK),
  subject_id (FK), teacher_id (FK), title, instructions, due_date,
  published_at, timestamps

homework_attachments
  id, tenant_id (FK), homework_id (FK), file_path, file_name, mime_type,
  size_bytes, timestamps

homework_status                  -- statut par élève (fait / à faire / en retard)
  id, tenant_id (FK), homework_id (FK), student_id (FK),
  status (pending|done|late), marked_by_user_id (FK nullable), timestamps
```

### Comportement

```
behavior_observations
  id, tenant_id (FK), student_id (FK), author_user_id (FK), category
  (positive|discipline|participation|incident|note_generale), title,
  description, occurred_at, visible_to_parent, timestamps
```

### Absences / retards

```
attendance_records
  id, tenant_id (FK), student_id (FK), type (absence|retard), date,
  start_time (nullable), end_time (nullable), reason, recorded_by_user_id (FK),
  timestamps

attendance_justifications
  id, tenant_id (FK), attendance_record_id (FK), submitted_by_user_id (FK),
  explanation, attachment_path (nullable), status (pending|approved|rejected),
  reviewed_by_user_id (FK nullable), reviewed_at (nullable), timestamps
```

### Messagerie

```
conversations
  id, tenant_id (FK), type (direct|broadcast), subject, created_by_user_id (FK),
  school_class_id (FK nullable), student_id (FK nullable), timestamps

conversation_participants
  id, tenant_id (FK), conversation_id (FK), user_id (FK), role_in_thread
  (teacher|parent|admin), last_read_at, timestamps

messages
  id, tenant_id (FK), conversation_id (FK), sender_user_id (FK), body,
  timestamps

message_attachments
  id, tenant_id (FK), message_id (FK), file_path, file_name, mime_type,
  size_bytes, timestamps

messaging_permissions             -- règles école: qui peut contacter qui
  id, tenant_id (FK), teacher_id (FK), can_be_contacted_directly (bool),
  requires_admin_relay (bool), timestamps
```

### Annonces

```
announcements
  id, tenant_id (FK), author_user_id (FK), title, body, category
  (info|reunion|sortie|examen|vacances|urgence), published_at, timestamps

announcement_targets                -- ciblage: all | class | group | user
  id, tenant_id (FK), announcement_id (FK), target_type
  (all|school_class|user_group|user), target_id (nullable), timestamps
```

### Emploi du temps / calendrier

```
timetable_slots
  id, tenant_id (FK), school_class_id (FK), subject_id (FK), teacher_id (FK),
  day_of_week (1-7), start_time, end_time, room, timestamps

academic_events                     -- calendrier académique (examens, vacances)
  id, tenant_id (FK), title, description, start_date, end_date, category,
  timestamps
```

### Notes / bulletins (module activable, structure prête dès le MVP)

```
grading_periods
  id, tenant_id (FK), school_year_id (FK), label (Trimestre 1...), timestamps

grades
  id, tenant_id (FK), student_id (FK), subject_id (FK), grading_period_id (FK),
  score, max_score, coefficient, comment, entered_by_user_id (FK), timestamps

report_cards
  id, tenant_id (FK), student_id (FK), grading_period_id (FK), file_path,
  generated_at, timestamps
```

### Documents

```
documents
  id, tenant_id (FK), title, category (bulletin|circulaire|reglement|
  calendrier|autre), file_path, visible_to (all|school_class|student|user),
  target_id (nullable), uploaded_by_user_id (FK), timestamps
```

### Notifications

```
notifications                        -- table standard Laravel notifications
  id (uuid), type, notifiable_type, notifiable_id, data (json), read_at,
  created_at, updated_at
  -- tenant_id dénormalisé dans `data` + index applicatif, car la table est
     polymorphique par design Laravel

device_tokens
  id, tenant_id (FK), user_id (FK), fcm_token, platform (android|ios),
  last_seen_at, timestamps

notification_preferences
  id, tenant_id (FK), user_id (FK), category (devoir|absence|message|
  annonce|bulletin|reunion), channel (push|email), is_enabled, timestamps
```

---

## 8. Relations entre les tables (résumé)

- `tenants` 1—N `users`, `students`, `school_classes`, … (toutes les tables
  métier) — clé de l'isolation multi-tenant.
- `parent_identities` 1—N `users` (un même parent, plusieurs comptes tenant).
- `users` (rôle enseignant) 1—1 `teachers` ; `teachers` N—N `school_classes`
  via `teacher_assignments` (avec `subject_id` en attribut de la relation).
- `students` N—N `users` (rôle parent) via `student_guardians`.
- `school_classes` 1—N `students`, 1—N `timetable_slots`, 1—N `homeworks`.
- `homeworks` 1—N `homework_attachments`, 1—N `homework_status` (1 par élève
  de la classe, générée à la publication du devoir).
- `students` 1—N `behavior_observations`, 1—N `attendance_records`,
  1—N `grades`.
- `attendance_records` 1—1 `attendance_justifications` (0 ou 1).
- `conversations` 1—N `messages`, N—N `users` via `conversation_participants`.
- `announcements` 1—N `announcement_targets` (ciblage polymorphique simple,
  pas de table polymorphe Eloquent pour rester lisible en SQL direct).
- `subscriptions` N—1 `plans` ; `plans` 1—N `plan_features`.
- Toute table métier référence `tenant_id` même quand une relation indirecte
  suffirait à le déduire (ex. `homework_status.tenant_id` est redondant avec
  `homeworks.tenant_id`) — **volontairement dénormalisé** pour que le
  Global Scope tenant fonctionne sur une simple colonne locale, sans jointure,
  sur 100 % des requêtes.

---

## 9. Architecture API

- Base : `/api/v1/...`, JSON, authentification **Laravel Sanctum** (tokens
  personnels pour mobile, cookies SPA pour le back-office web si besoin d'un
  futur front séparé).
- Un tenant n'apparaît **jamais** dans l'URL (`api/v1/schools/{tenant}/...`)
  pour éviter qu'un client change l'ID dans l'URL : le tenant est résolu
  uniquement depuis le token authentifié.
- Connexion initiale (avant tenant connu) : `POST /api/v1/auth/login`
  (email/téléphone + mot de passe), retourne un token scpermis au(x)
  tenant(s) de l'utilisateur. Si le compte `parent_identity` a plusieurs
  comptes tenant, l'app affiche un sélecteur d'école puis appelle
  `POST /api/v1/auth/select-context` qui émet le token définitif pour le
  contexte choisi.
- Endpoints principaux (exemples, non exhaustif) :
  - `GET /api/v1/me` (profil + tenant + branding)
  - `GET /api/v1/children` (enfants du parent connecté)
  - `GET /api/v1/children/{student}/dashboard`
  - `GET /api/v1/children/{student}/homeworks?range=today|tomorrow|week|late`
  - `GET /api/v1/children/{student}/behavior`
  - `GET /api/v1/children/{student}/attendance`
  - `POST /api/v1/attendance/{record}/justify`
  - `GET|POST /api/v1/conversations`, `GET|POST /api/v1/conversations/{c}/messages`
  - `GET /api/v1/announcements`
  - `GET /api/v1/children/{student}/timetable`
  - `GET /api/v1/children/{student}/grades` (si module actif)
  - `GET /api/v1/documents`
  - `PATCH /api/v1/notification-preferences`
  - `POST /api/v1/devices` (enregistrement token FCM)
  - Back-office (rôles école/direction/enseignant) : CRUD REST classique sous
    `/api/v1/admin/...` protégé par policies + permissions spatie.
  - Plateforme (Super Admin) : `/api/v1/platform/...` (tenants, plans,
    abonnements), guard Sanctum distinct `platform`.
- Toute réponse liste est paginée (`?page=`), toute réponse suit une
  enveloppe standard `{ data, meta }` (Laravel API Resources).
- Rate limiting par défaut (`throttle:api`), plus strict sur
  `auth/login` (protection brute-force, voir §17).
- Versionnement : `v1` figé une fois publié ; un changement cassant crée
  `v2` plutôt que de modifier `v1` (contrat mobile en production).

---

## 10. Liste des écrans mobiles (Flutter)

**Onboarding / auth**
1. Splash (résolution du branding si session existante)
2. Connexion (email/téléphone + mot de passe)
3. Sélecteur d'enfant/école (si plusieurs)
4. Mot de passe oublié

**Parent**
5. Tableau de bord (par enfant sélectionné)
6. Devoirs — Aujourd'hui / Demain / Semaine / En retard
7. Détail d'un devoir (pièces jointes, consignes)
8. Comportement — historique
9. Absences & retards — historique + justification
10. Messagerie — liste des conversations
11. Conversation (fil de discussion)
12. Nouveau message (si autorisé)
13. Annonces — liste + détail
14. Emploi du temps — jour / semaine
15. Calendrier académique
16. Notes / bulletin (si module actif)
17. Documents
18. Notifications — centre de notifications
19. Réglages de notifications
20. Profil / mes enfants / changer d'école
21. Paramètres (langue, mot de passe, déconnexion, révoquer mes sessions)

**Enseignant** (même app, contexte différent)
22. Tableau de bord enseignant (mes classes du jour)
23. Publier un devoir
24. Publier une observation de comportement
25. Saisir une absence/retard
26. Mes conversations (élèves/classes autorisés)
27. Mes classes / emploi du temps

---

## 11. Liste des écrans d'administration (back-office web)

1. Connexion back-office
2. Tableau de bord école (KPIs §13)
3. Élèves — liste, fiche, import CSV, historique de classe
4. Classes — liste, création, affectation enseignant principal
5. Parents — liste, fiche, rattachement à un/plusieurs élèves
6. Enseignants — liste, fiche, affectations classe × matière
7. Matières
8. Emploi du temps — grille par classe, édition par créneau
9. Devoirs — vue consolidée, création au nom d'un enseignant si besoin
10. Comportement — vue consolidée, statistiques par classe
11. Absences — saisie, validation des justificatifs
12. Messagerie — supervision, règles d'autorisation par enseignant
13. Annonces — création + ciblage
14. Notes / bulletins (si module actif) — saisie, génération bulletin PDF
15. Documents — dépôt, ciblage
16. Notifications — historique des envois
17. Rôles & permissions — utilisateurs internes, rôles personnalisés
18. Paramètres de l'école — logo, couleurs, coordonnées, année scolaire,
    activation des modules
19. Abonnement — plan actuel, limites, historique (lecture seule côté école)

**Back-office plateforme (Super Admin Scolia)**
20. Liste des écoles (tenants) — statut, plan, élèves
21. Création d'une école (provisioning)
22. Détail école — configuration, abonnement, journal d'activité
23. Plans & tarifs — CRUD des plans (§17, jamais codé en dur)
24. Statistiques globales d'usage
25. Journaux d'audit / sécurité

---

## 12. Parcours utilisateur parent

1. Téléchargement de l'app → écran de connexion.
2. Connexion avec les identifiants fournis par l'école (créés par
   l'administration à l'inscription de l'élève — pas d'auto-inscription
   libre, condition de confiance pour une école privée).
3. Si plusieurs enfants/écoles : sélection du contexte actif ; l'app
   applique immédiatement le branding de l'école choisie (logo, couleurs).
4. Arrivée sur le tableau de bord : photo/nom/classe de l'enfant, devoirs du
   jour, derniers messages, dernière observation de comportement, absences
   récentes, prochain événement.
5. Une notification push (« Nouveau devoir de Mathématiques ») ramène
   directement sur l'écran concerné (deep link).
6. En cas d'absence signalée par l'école, notification immédiate ; le
   parent peut justifier depuis l'app (texte + photo du justificatif).
7. Le parent peut écrire à l'enseignant **seulement si l'école l'autorise**
   pour cet enseignant/cette classe ; sinon le champ de saisie est
   remplacé par un message expliquant de passer par l'administration.
8. Changement d'enfant à tout moment via un sélecteur toujours visible dans
   l'en-tête du tableau de bord.

---

## 13. Parcours utilisateur enseignant

1. Connexion (même app, rôle enseignant détecté automatiquement).
2. Tableau de bord : classes du jour selon l'emploi du temps.
3. Sélection d'une classe → publication d'un devoir (matière pré-remplie
   selon son affectation, titre, consignes, pièce jointe, date limite) :
   3 champs minimum, publication en un tap.
4. Peut publier une observation de comportement pour un élève de sa classe
   (positive ou à signaler) — jamais visible comme « note chiffrée », reste
   qualitatif au MVP.
5. Peut saisir une absence/retard constaté en classe (déclenche la
   notification parent immédiatement).
6. Consulte les messages des parents de ses classes, dans les limites
   fixées par l'administration (pas de contact non sollicité vers des
   parents d'autres classes).
7. Consulte son propre emploi du temps.

---

## 14. Parcours administrateur (école)

1. Connexion back-office web.
2. Configuration initiale de l'école (une seule fois) : logo, couleurs,
   coordonnées, année scolaire, activation des modules (ex : notes
   désactivées si l'école ne veut pas les publier via l'app).
3. Import des élèves (CSV) → création automatique des comptes parents (mot
   de passe temporaire envoyé par email/SMS) → rattachement élève-classe.
4. Création des enseignants et de leurs affectations classe × matière.
5. Configuration des règles de messagerie (quels enseignants sont
   joignables directement).
6. Utilisation quotidienne : validation des justificatifs d'absence,
   publication d'annonces, supervision du tableau de bord (KPIs), gestion
   des rôles internes (direction, surveillant, comptable si activés).
7. Suivi de son abonnement (lecture seule ; upgrade = contact commercial ou
   self-service en V2).

---

## 15. Système de rôles et permissions

Rôles fournis nativement (via `spatie/laravel-permission`, teams = tenant) :

| Rôle | Portée | Exemples de permissions |
|---|---|---|
| **super_admin** (plateforme, hors tenant) | Toutes les écoles | gérer tenants, plans, abonnements, support |
| **school_admin** | 1 école | tout gérer sauf configuration plateforme |
| **direction** | 1 école | comme school_admin sauf gestion des rôles internes (configurable) |
| **teacher** | ses classes/matières affectées | publier devoir/comportement/absence sur ses classes, messagerie limitée |
| **parent** | ses enfants uniquement | lecture des données de ses enfants, messagerie limitée, justification d'absence |
| **surveillant** *(optionnel)* | classes affectées | saisir absences/retards, comportement |
| **comptable** *(optionnel, V2)* | 1 école | module frais de scolarité |
| **eleve** *(optionnel, V3)* | lui-même | lecture seule de son propre emploi du temps/devoirs |

Les permissions sont des permissions **spatie** granulaires
(`homework.create`, `announcement.publish`, `student.view`, …) assignées aux
rôles ; une école peut créer des rôles personnalisés en combinant des
permissions existantes (V2), sans toucher au code. Toute autorisation
passe par une **Policy Laravel** qui vérifie à la fois la permission et
l'appartenance au même tenant (défense en profondeur, voir §6).

---

## 16. Système de notifications

- Canal principal : **push FCM**, via les notifications Laravel
  (`Notification::send` + channel `fcm` custom), envoyées **de façon
  synchrone** dans la requête HTTP (pas de `ShouldQueue`) — évite de
  dépendre d'un worker de file d'attente dédié sur l'hébergement.
- Chaque catégorie métier (devoir, absence, message, annonce, bulletin,
  réunion) déclenche un `Notification` Laravel dédié, ce qui permet à
  l'utilisateur de désactiver une catégorie sans toucher aux autres
  (`notification_preferences`).
- Un job planifié nettoie les tokens FCM invalides (retour d'erreur
  Firebase) pour ne pas accumuler du bruit.
- Deep linking : chaque notification transporte un `type` + `id` permettant
  à l'app d'ouvrir directement le bon écran.
- Historique consultable dans l'app (centre de notifications) via la table
  standard Laravel `notifications`.
- Envois de masse (annonce à toute une école) : dispatchés en jobs
  batched (`Bus::batch`) avec limitation de débit vers FCM (respect des
  quotas Firebase), jamais en boucle synchrone.
- V2/V3 : ajout de canaux email et SMS/WhatsApp, sans changement du modèle
  (juste un nouveau channel Laravel).

---

## 17. Stratégie de sécurité

- **Authentification** : Laravel Sanctum, tokens à durée de vie limitée
  pour le mobile (refresh via re-login ou refresh token en V2), mots de
  passe hashés `bcrypt`/`argon2id` (config Laravel par défaut).
- **Politique de mot de passe** : longueur minimale, vérification contre
  les mots de passe compromis (`Password::defaults()` avec règle
  `uncompromised()`), changement obligatoire à la première connexion pour
  les comptes créés par import.
- **Limitation des tentatives de connexion** : throttle Laravel
  (`RateLimiter`) par IP **et** par compte, verrouillage progressif,
  journalisé dans `audit_logs`.
- **Sessions/appareils** : chaque token Sanctum est lié à un `device_name` ;
  écran « Mes sessions actives » permettant au parent/à l'enseignant de
  révoquer un appareil ; expiration automatique après inactivité prolongée.
- **HTTPS obligatoire** partout (HSTS activé), API jamais servie en clair.
- **Isolation stricte des tenants** : voir §6 (colonne systématique + global
  scope + policy + tests dédiés). C'est la mesure de sécurité la plus
  critique du produit, car les données concernent des enfants.
- **Fichiers** : upload validé (type MIME, taille), stocké hors du
  webroot public, servi via une route signée temporaire
  (`Storage::temporaryUrl` ou équivalent), jamais par chemin direct
  prévisible.
- **Audit** : table `audit_logs` sur toutes les actions sensibles
  (création/suppression d'utilisateur, changement de rôle, consultation de
  bulletin, export de données, connexion Super Admin sur un tenant).
- **Sauvegardes** : sauvegarde quotidienne chiffrée de la base + fichiers,
  testée par restauration périodique (une sauvegarde non testée n'est pas
  une sauvegarde).
- **Accès Super Admin plateforme** : jamais d'accès direct aux données
  pédagogiques d'une école sans action explicitement journalisée
  (« mode support » avec bannière visible + entrée d'audit), pour
  respecter la confidentialité qui inquiète les écoles clientes.
- **Conformité données mineurs** : minimisation des données collectées sur
  les enfants, durée de conservation définie par école/année scolaire,
  export/suppression des données à la demande d'une école qui quitte le
  service.
- **Dépendances** : `composer audit` / Dependabot en CI, mise à jour de
  sécurité prioritaire sur toute autre tâche.

---

## 18. Modèle SaaS

- Facturation à l'école, **annuelle** par défaut (mensuelle possible en V2).
- Plans **entièrement pilotés depuis le back-office plateforme**
  (`plans` + `plan_features`, §7) : aucun prix, quota ou nom de plan codé
  en dur dans l'application. Exemples de plans de départ (modifiables sans
  déploiement) :
  - **Starter** — jusqu'à 300 élèves
  - **Standard** — jusqu'à 800 élèves
  - **Premium** — au-delà, + fonctionnalités avancées (notes complètes,
    statistiques avancées, support prioritaire)
- `subscription_modules` permet en plus d'activer/désactiver un module
  indépendamment du plan (ex : une école Premium peut choisir de ne pas
  publier les notes via l'app).
- Compteur `students_count_cache` sur `subscriptions`, recalculé à chaque
  changement d'effectif, comparé à `plans.max_students` pour bloquer/alerter
  au dépassement (avertissement avant blocage, jamais de coupure brutale
  sans préavis).
- Statuts d'abonnement (`trialing`, `active`, `past_due`, `canceled`) pilotent
  l'accès : un abonnement `past_due` bascule l'école en mode lecture seule
  avant suspension complète, jamais de suppression de données.
- Facturation elle-même (paiement, factures) volontairement **hors MVP** :
  gérée manuellement/hors-ligne au lancement (marché africain, moyens de
  paiement variés) ; l'intégration d'un fournisseur de paiement (Stripe,
  mobile money) est un chantier V2 séparé, sans impact sur le schéma déjà
  prévu (`subscriptions.status` suffit à piloter l'accès quel que soit le
  moyen de paiement réel).

---

## 19. Plan de développement par étapes

**Étape 0 — Fondations (avant toute fonctionnalité visible)**
Projet Laravel, MySQL, multi-tenant (tenants, global scope, policies),
authentification Sanctum, rôles/permissions, CI (tests + lint), squelette
Flutter connecté à l'API (écran de connexion réel).
→ Livrable : une école de démo peut se connecter et voir un tableau de bord
vide mais réellement isolé.

**Étape 1 — Cœur école**
Écoles (tenant settings), années scolaires, classes, matières, élèves,
parents, enseignants, affectations. Back-office web correspondant.
→ Livrable : une école peut importer ses élèves et ses classes elle-même.

**Étape 2 — Cahier de liaison (modules MVP prioritaires)**
Devoirs/cahier de texte, comportement, absences/retards + justification,
notifications push associées.
→ Livrable : premier module utilisable quotidiennement par un parent réel.

**Étape 3 — Communication**
Messagerie (avec règles d'autorisation), annonces, emploi du temps /
calendrier.
→ Livrable : MVP fonctionnellement complet.

**Étape 4 — Pilotage**
Tableau de bord école (KPIs), rôles/permissions avancés côté back-office,
personnalisation complète (branding), gestion des plans/abonnements côté
plateforme.
→ Livrable : le produit est vendable en autonomie à une 2ᵉ puis une 3ᵉ école.

**Étape 5 — Durcissement**
Audit de sécurité complet, tests de charge (envoi de notifications de
masse), tests d'isolation multi-tenant systématiques, sauvegardes/restauration
testées, documentation d'exploitation.
→ Livrable : mise en production commerciale.

**V2** : notes/bulletins complets, documents, justification enrichie,
paiements, self-service upgrade de plan.
**V3** : IA (résumés, assistant, détection avec validation humaine,
chatbot), canaux SMS/WhatsApp, client web parent.

À chaque étape : revue explicite des risques avant de passer à la
suivante (ne pas construire l'étape N+1 sur une isolation tenant ou une
sécurité d'authentification non validée à l'étape N).
