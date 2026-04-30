-- ══════════════════════════════════════════════════════════════════
-- SCOLIA — Script d'installation de la base de données (PostgreSQL)
-- Version : 2.0.0
-- IMPORTANT : Ce script crée uniquement la structure (aucune donnée)
-- Créer la base avant d'exécuter :
--   createdb -U postgres scolia
--   psql -U postgres -d scolia -f install.sql
-- ══════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════
-- GESTION DES UTILISATEURS ET ÉCOLES
-- ══════════════════════════════════════════════

CREATE TABLE ecoles (
  id                    SERIAL PRIMARY KEY,
  nom                   VARCHAR(255) NOT NULL,
  slug                  VARCHAR(100) UNIQUE NOT NULL,
  logo_url              VARCHAR(500),
  ville                 VARCHAR(100),
  telephone             VARCHAR(20),
  email                 VARCHAR(150),
  adresse               TEXT,
  plan                  VARCHAR(20)  DEFAULT 'starter' CHECK (plan IN ('starter','pro','enterprise')),
  date_debut_abonnement DATE,
  date_fin_abonnement   DATE,
  actif                 BOOLEAN      DEFAULT TRUE,
  annee_scolaire        VARCHAR(20),
  date_debut_scolarite  DATE,
  date_fin_scolarite    DATE,
  created_at            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE utilisateurs (
  id          SERIAL PRIMARY KEY,
  ecole_id    INTEGER     NOT NULL,
  telephone   VARCHAR(20) NOT NULL,
  prenom      VARCHAR(100),
  nom         VARCHAR(100),
  role        VARCHAR(20) NOT NULL CHECK (role IN ('super_admin','school_admin','teacher','parent')),
  actif       BOOLEAN     DEFAULT TRUE,
  fcm_token   VARCHAR(500),
  created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_util_ecole    FOREIGN KEY (ecole_id) REFERENCES ecoles(id) ON DELETE CASCADE,
  CONSTRAINT unique_tel_ecole UNIQUE (telephone, ecole_id)
);

CREATE TABLE otp_codes (
  id          SERIAL PRIMARY KEY,
  telephone   VARCHAR(20) NOT NULL,
  code        VARCHAR(6)  NOT NULL,
  expires_at  TIMESTAMP   NOT NULL,
  utilise     BOOLEAN     DEFAULT FALSE,
  created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_otp_telephone ON otp_codes(telephone);
CREATE INDEX idx_otp_expires   ON otp_codes(expires_at);

-- ══════════════════════════════════════════════
-- GESTION DES ÉLÈVES ET DOSSIERS
-- ══════════════════════════════════════════════

CREATE TABLE classes (
  id              SERIAL PRIMARY KEY,
  ecole_id        INTEGER     NOT NULL,
  nom             VARCHAR(50) NOT NULL,
  niveau          VARCHAR(20),
  annee_scolaire  VARCHAR(20),
  enseignant_id   INTEGER,
  CONSTRAINT fk_cl_ecole      FOREIGN KEY (ecole_id)      REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_cl_enseignant FOREIGN KEY (enseignant_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE TABLE eleves (
  id              SERIAL PRIMARY KEY,
  ecole_id        INTEGER      NOT NULL,
  classe_id       INTEGER,
  prenom          VARCHAR(100) NOT NULL,
  nom             VARCHAR(100) NOT NULL,
  date_naissance  DATE,
  matricule       VARCHAR(50),
  photo_url       VARCHAR(500),
  actif           BOOLEAN      DEFAULT TRUE,
  CONSTRAINT fk_el_ecole  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id)  ON DELETE CASCADE,
  CONSTRAINT fk_el_classe FOREIGN KEY (classe_id) REFERENCES classes(id) ON DELETE SET NULL
);

CREATE TABLE dossiers_parents (
  id               SERIAL PRIMARY KEY,
  parent_id        INTEGER NOT NULL,
  eleve_id         INTEGER NOT NULL,
  actif            BOOLEAN DEFAULT FALSE,
  date_activation  DATE,
  date_expiration  DATE,
  CONSTRAINT fk_dp_parent        FOREIGN KEY (parent_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  CONSTRAINT fk_dp_eleve         FOREIGN KEY (eleve_id)  REFERENCES eleves(id)       ON DELETE CASCADE,
  CONSTRAINT unique_parent_eleve UNIQUE (parent_id, eleve_id)
);

-- ══════════════════════════════════════════════
-- MODULE CAHIER DE LIAISON
-- ══════════════════════════════════════════════

CREATE TABLE messages_liaison (
  id             SERIAL PRIMARY KEY,
  ecole_id       INTEGER     NOT NULL,
  auteur_id      INTEGER     NOT NULL,
  classe_id      INTEGER,
  categorie      VARCHAR(20) DEFAULT 'info' CHECK (categorie IN ('info','devoir','autorisation','retard','autre')),
  titre          VARCHAR(255),
  contenu        TEXT        NOT NULL,
  necessite_ack  BOOLEAN     DEFAULT FALSE,
  created_at     TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_msg_ecole  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_msg_auteur FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_classe FOREIGN KEY (classe_id) REFERENCES classes(id)     ON DELETE SET NULL
);

CREATE TABLE accuses_reception (
  id          SERIAL PRIMARY KEY,
  message_id  INTEGER   NOT NULL,
  parent_id   INTEGER   NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ack_message FOREIGN KEY (message_id) REFERENCES messages_liaison(id) ON DELETE CASCADE,
  CONSTRAINT fk_ack_parent  FOREIGN KEY (parent_id)  REFERENCES utilisateurs(id)     ON DELETE CASCADE,
  CONSTRAINT unique_ack     UNIQUE (message_id, parent_id)
);

-- ══════════════════════════════════════════════
-- MODULE REMARQUES PÉDAGOGIQUES
-- ══════════════════════════════════════════════

CREATE TABLE remarques (
  id          SERIAL PRIMARY KEY,
  ecole_id    INTEGER   NOT NULL,
  auteur_id   INTEGER   NOT NULL,
  eleve_id    INTEGER   NOT NULL,
  categorie   VARCHAR(20) DEFAULT 'autre' CHECK (categorie IN ('felicitation','comportement','absence','retard','sante','autre')),
  priorite    VARCHAR(15) DEFAULT 'info'  CHECK (priorite  IN ('info','avertissement','urgent')),
  message     TEXT      NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rem_ecole  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_rem_auteur FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  CONSTRAINT fk_rem_eleve  FOREIGN KEY (eleve_id)  REFERENCES eleves(id)      ON DELETE CASCADE
);

CREATE TABLE remarques_lues (
  id           SERIAL PRIMARY KEY,
  remarque_id  INTEGER   NOT NULL,
  parent_id    INTEGER   NOT NULL,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rl_remarque FOREIGN KEY (remarque_id) REFERENCES remarques(id)     ON DELETE CASCADE,
  CONSTRAINT fk_rl_parent   FOREIGN KEY (parent_id)   REFERENCES utilisateurs(id)  ON DELETE CASCADE,
  CONSTRAINT unique_lu      UNIQUE (remarque_id, parent_id)
);

-- ══════════════════════════════════════════════
-- MODULE CALENDRIER / ÉVÉNEMENTS
-- ══════════════════════════════════════════════

CREATE TABLE evenements (
  id           SERIAL PRIMARY KEY,
  ecole_id     INTEGER     NOT NULL,
  auteur_id    INTEGER     NOT NULL,
  titre        VARCHAR(255) NOT NULL,
  description  TEXT,
  date_debut   DATE        NOT NULL,
  heure_debut  TIME,
  lieu         VARCHAR(255),
  type         VARCHAR(20) DEFAULT 'autre' CHECK (type IN ('reunion','sortie','vacances','fete','examen','autre')),
  created_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ev_ecole  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_ev_auteur FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- ══════════════════════════════════════════════
-- MODULE NOTES
-- ══════════════════════════════════════════════

CREATE TABLE matieres (
  id           SERIAL PRIMARY KEY,
  ecole_id     INTEGER      NOT NULL,
  classe_id    INTEGER,
  nom          VARCHAR(100) NOT NULL,
  coefficient  DECIMAL(3,1) DEFAULT 1.0,
  CONSTRAINT fk_mat_ecole  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id)  ON DELETE CASCADE,
  CONSTRAINT fk_mat_classe FOREIGN KEY (classe_id) REFERENCES classes(id) ON DELETE SET NULL
);

CREATE TABLE periodes_evaluation (
  id              SERIAL PRIMARY KEY,
  ecole_id        INTEGER     NOT NULL,
  nom             VARCHAR(50) NOT NULL,
  date_debut      DATE,
  date_fin        DATE,
  annee_scolaire  VARCHAR(20),
  CONSTRAINT fk_pe_ecole FOREIGN KEY (ecole_id) REFERENCES ecoles(id) ON DELETE CASCADE
);

CREATE TABLE notes (
  id               SERIAL PRIMARY KEY,
  ecole_id         INTEGER      NOT NULL,
  eleve_id         INTEGER      NOT NULL,
  matiere_id       INTEGER      NOT NULL,
  periode_id       INTEGER      NOT NULL,
  saisie_par       INTEGER      NOT NULL,
  note             DECIMAL(4,2) NOT NULL,
  note_sur         DECIMAL(4,2) DEFAULT 20.00,
  commentaire      VARCHAR(500),
  type_evaluation  VARCHAR(15)  DEFAULT 'controle' CHECK (type_evaluation IN ('controle','devoir','examen','oral','autre')),
  date_evaluation  DATE,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_note_ecole   FOREIGN KEY (ecole_id)   REFERENCES ecoles(id)              ON DELETE CASCADE,
  CONSTRAINT fk_note_eleve   FOREIGN KEY (eleve_id)   REFERENCES eleves(id)              ON DELETE CASCADE,
  CONSTRAINT fk_note_matiere FOREIGN KEY (matiere_id) REFERENCES matieres(id)            ON DELETE CASCADE,
  CONSTRAINT fk_note_periode FOREIGN KEY (periode_id) REFERENCES periodes_evaluation(id) ON DELETE CASCADE,
  CONSTRAINT fk_note_saisie  FOREIGN KEY (saisie_par) REFERENCES utilisateurs(id)        ON DELETE CASCADE
);

CREATE INDEX idx_note_eleve_periode ON notes(eleve_id, periode_id);

-- ══════════════════════════════════════════════
-- MODULE FRAIS DE SCOLARITÉ
-- ══════════════════════════════════════════════

CREATE TABLE frais_scolarite (
  id              SERIAL PRIMARY KEY,
  ecole_id        INTEGER       NOT NULL,
  eleve_id        INTEGER       NOT NULL,
  annee_scolaire  VARCHAR(20)   NOT NULL,
  mois            SMALLINT      NOT NULL,
  montant_du      DECIMAL(10,2) NOT NULL,
  montant_paye    DECIMAL(10,2) DEFAULT 0.00,
  statut          VARCHAR(15)   DEFAULT 'non_paye' CHECK (statut IN ('non_paye','partiel','paye')),
  date_paiement   DATE,
  confirme_par    INTEGER,
  note_admin      VARCHAR(500),
  created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_frais_ecole   FOREIGN KEY (ecole_id)     REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_frais_eleve   FOREIGN KEY (eleve_id)     REFERENCES eleves(id)      ON DELETE CASCADE,
  CONSTRAINT fk_frais_confirm FOREIGN KEY (confirme_par) REFERENCES utilisateurs(id) ON DELETE SET NULL,
  CONSTRAINT unique_frais     UNIQUE (eleve_id, annee_scolaire, mois)
);

-- Remplace ON UPDATE CURRENT_TIMESTAMP (non supporté par PostgreSQL)
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_frais_updated_at
BEFORE UPDATE ON frais_scolarite
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ══════════════════════════════════════════════
-- NOTIFICATIONS
-- ══════════════════════════════════════════════

CREATE TABLE notifications (
  id               SERIAL PRIMARY KEY,
  ecole_id         INTEGER      NOT NULL,
  destinataire_id  INTEGER      NOT NULL,
  titre            VARCHAR(255) NOT NULL,
  corps            TEXT,
  type             VARCHAR(20)  DEFAULT 'autre' CHECK (type IN ('liaison','remarque','note','frais','evenement','autre')),
  reference_id     INTEGER,
  lue              BOOLEAN      DEFAULT FALSE,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_ecole        FOREIGN KEY (ecole_id)        REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_notif_destinataire FOREIGN KEY (destinataire_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

CREATE INDEX idx_notif_destinataire ON notifications(destinataire_id);
CREATE INDEX idx_notif_lue          ON notifications(lue);
