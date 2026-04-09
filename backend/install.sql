-- ══════════════════════════════════════════════════════════════════
-- SCOLIA — Script d'installation de la base de données
-- Version : 1.0.0
-- IMPORTANT : Ce script crée uniquement la structure (aucune donnée)
-- ══════════════════════════════════════════════════════════════════

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+01:00";
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS scolia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE scolia;

-- ══════════════════════════════════════════════
-- GESTION DES UTILISATEURS ET ÉCOLES
-- ══════════════════════════════════════════════

CREATE TABLE ecoles (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  nom                   VARCHAR(255) NOT NULL,
  slug                  VARCHAR(100) UNIQUE NOT NULL,
  logo_url              VARCHAR(500),
  ville                 VARCHAR(100),
  telephone             VARCHAR(20),
  email                 VARCHAR(150),
  adresse               TEXT,
  plan                  ENUM('starter','pro','enterprise') DEFAULT 'starter',
  date_debut_abonnement DATE,
  date_fin_abonnement   DATE,
  actif                 BOOLEAN DEFAULT TRUE,
  annee_scolaire        VARCHAR(20),
  date_debut_scolarite  DATE,
  date_fin_scolarite    DATE,
  created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE utilisateurs (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id    INT NOT NULL,
  telephone   VARCHAR(20) NOT NULL,
  prenom      VARCHAR(100),
  nom         VARCHAR(100),
  role        ENUM('super_admin','school_admin','teacher','parent') NOT NULL,
  actif       BOOLEAN DEFAULT TRUE,
  fcm_token   VARCHAR(500),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id) REFERENCES ecoles(id) ON DELETE CASCADE,
  UNIQUE KEY unique_tel_ecole (telephone, ecole_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE otp_codes (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  telephone   VARCHAR(20) NOT NULL,
  code        VARCHAR(6)  NOT NULL,
  expires_at  DATETIME    NOT NULL,
  utilise     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_telephone (telephone),
  INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- GESTION DES ÉLÈVES ET DOSSIERS
-- ══════════════════════════════════════════════

CREATE TABLE classes (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id        INT NOT NULL,
  nom             VARCHAR(50) NOT NULL,
  niveau          VARCHAR(20),
  annee_scolaire  VARCHAR(20),
  enseignant_id   INT,
  FOREIGN KEY (ecole_id)      REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (enseignant_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE eleves (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id        INT NOT NULL,
  classe_id       INT,
  prenom          VARCHAR(100) NOT NULL,
  nom             VARCHAR(100) NOT NULL,
  date_naissance  DATE,
  matricule       VARCHAR(50),
  photo_url       VARCHAR(500),
  actif           BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (classe_id) REFERENCES classes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dossiers_parents (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  parent_id        INT NOT NULL,
  eleve_id         INT NOT NULL,
  actif            BOOLEAN DEFAULT FALSE,
  date_activation  DATE,
  date_expiration  DATE,
  FOREIGN KEY (parent_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  FOREIGN KEY (eleve_id)  REFERENCES eleves(id) ON DELETE CASCADE,
  UNIQUE KEY unique_parent_eleve (parent_id, eleve_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- MODULE CAHIER DE LIAISON
-- ══════════════════════════════════════════════

CREATE TABLE messages_liaison (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id       INT NOT NULL,
  auteur_id      INT NOT NULL,
  classe_id      INT,
  categorie      ENUM('info','devoir','autorisation','retard','autre') DEFAULT 'info',
  titre          VARCHAR(255),
  contenu        TEXT NOT NULL,
  necessite_ack  BOOLEAN DEFAULT FALSE,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  FOREIGN KEY (classe_id) REFERENCES classes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE accuses_reception (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  message_id  INT NOT NULL,
  parent_id   INT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (message_id) REFERENCES messages_liaison(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_id)  REFERENCES utilisateurs(id) ON DELETE CASCADE,
  UNIQUE KEY unique_ack (message_id, parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- MODULE REMARQUES PÉDAGOGIQUES
-- ══════════════════════════════════════════════

CREATE TABLE remarques (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id    INT NOT NULL,
  auteur_id   INT NOT NULL,
  eleve_id    INT NOT NULL,
  categorie   ENUM('felicitation','comportement','absence','retard','sante','autre') DEFAULT 'autre',
  priorite    ENUM('info','avertissement','urgent') DEFAULT 'info',
  message     TEXT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  FOREIGN KEY (eleve_id)  REFERENCES eleves(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE remarques_lues (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  remarque_id  INT NOT NULL,
  parent_id    INT NOT NULL,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (remarque_id) REFERENCES remarques(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_id)   REFERENCES utilisateurs(id) ON DELETE CASCADE,
  UNIQUE KEY unique_lu (remarque_id, parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- MODULE CALENDRIER / ÉVÉNEMENTS
-- ══════════════════════════════════════════════

CREATE TABLE evenements (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id     INT NOT NULL,
  auteur_id    INT NOT NULL,
  titre        VARCHAR(255) NOT NULL,
  description  TEXT,
  date_debut   DATE NOT NULL,
  heure_debut  TIME,
  lieu         VARCHAR(255),
  type         ENUM('reunion','sortie','vacances','fete','examen','autre') DEFAULT 'autre',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- MODULE NOTES
-- ══════════════════════════════════════════════

CREATE TABLE matieres (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id     INT NOT NULL,
  classe_id    INT,
  nom          VARCHAR(100) NOT NULL,
  coefficient  DECIMAL(3,1) DEFAULT 1.0,
  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (classe_id) REFERENCES classes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE periodes_evaluation (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id        INT NOT NULL,
  nom             VARCHAR(50) NOT NULL,
  date_debut      DATE,
  date_fin        DATE,
  annee_scolaire  VARCHAR(20),
  FOREIGN KEY (ecole_id) REFERENCES ecoles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE notes (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id          INT NOT NULL,
  eleve_id          INT NOT NULL,
  matiere_id        INT NOT NULL,
  periode_id        INT NOT NULL,
  saisie_par        INT NOT NULL,
  note              DECIMAL(4,2) NOT NULL,
  note_sur          DECIMAL(4,2) DEFAULT 20.00,
  commentaire       VARCHAR(500),
  type_evaluation   ENUM('controle','devoir','examen','oral','autre') DEFAULT 'controle',
  date_evaluation   DATE,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id)   REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (eleve_id)   REFERENCES eleves(id) ON DELETE CASCADE,
  FOREIGN KEY (matiere_id) REFERENCES matieres(id) ON DELETE CASCADE,
  FOREIGN KEY (periode_id) REFERENCES periodes_evaluation(id) ON DELETE CASCADE,
  FOREIGN KEY (saisie_par) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- MODULE FRAIS DE SCOLARITÉ
-- ══════════════════════════════════════════════

CREATE TABLE frais_scolarite (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id        INT NOT NULL,
  eleve_id        INT NOT NULL,
  annee_scolaire  VARCHAR(20) NOT NULL,
  mois            TINYINT NOT NULL,
  montant_du      DECIMAL(10,2) NOT NULL,
  montant_paye    DECIMAL(10,2) DEFAULT 0.00,
  statut          ENUM('non_paye','partiel','paye') DEFAULT 'non_paye',
  date_paiement   DATE,
  confirme_par    INT,
  note_admin      VARCHAR(500),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id)     REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (eleve_id)     REFERENCES eleves(id) ON DELETE CASCADE,
  FOREIGN KEY (confirme_par) REFERENCES utilisateurs(id) ON DELETE SET NULL,
  UNIQUE KEY unique_frais (eleve_id, annee_scolaire, mois)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ══════════════════════════════════════════════
-- NOTIFICATIONS
-- ══════════════════════════════════════════════

CREATE TABLE notifications (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  ecole_id         INT NOT NULL,
  destinataire_id  INT NOT NULL,
  titre            VARCHAR(255) NOT NULL,
  corps            TEXT,
  type             ENUM('liaison','remarque','note','frais','evenement','autre') DEFAULT 'autre',
  reference_id     INT,
  lue              BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ecole_id)        REFERENCES ecoles(id) ON DELETE CASCADE,
  FOREIGN KEY (destinataire_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  INDEX idx_destinataire (destinataire_id),
  INDEX idx_lue (lue)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
