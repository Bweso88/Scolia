-- ══════════════════════════════════════════════════════════════════
-- SCOLIA — Migration v2 : Modules Notes et Frais de scolarité
-- À exécuter sur une base de données Scolia v1 existante
-- ══════════════════════════════════════════════════════════════════

USE scolia;

-- Matières par classe
CREATE TABLE IF NOT EXISTS `matieres` (
  `id`           INT AUTO_INCREMENT PRIMARY KEY,
  `ecole_id`     INT           NOT NULL,
  `classe_id`    INT           DEFAULT NULL,
  `nom`          VARCHAR(100)  NOT NULL,
  `coefficient`  DECIMAL(3,1)  NOT NULL DEFAULT 1.0,
  CONSTRAINT `fk_mat_ecole`  FOREIGN KEY (`ecole_id`)  REFERENCES `ecoles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mat_classe` FOREIGN KEY (`classe_id`) REFERENCES `classes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Périodes d'évaluation (trimestres)
CREATE TABLE IF NOT EXISTS `periodes_evaluation` (
  `id`              INT AUTO_INCREMENT PRIMARY KEY,
  `ecole_id`        INT          NOT NULL,
  `nom`             VARCHAR(50)  NOT NULL,
  `date_debut`      DATE         DEFAULT NULL,
  `date_fin`        DATE         DEFAULT NULL,
  `annee_scolaire`  VARCHAR(20)  DEFAULT NULL,
  CONSTRAINT `fk_periode_ecole` FOREIGN KEY (`ecole_id`) REFERENCES `ecoles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notes des élèves
CREATE TABLE IF NOT EXISTS `notes` (
  `id`               INT AUTO_INCREMENT PRIMARY KEY,
  `ecole_id`         INT           NOT NULL,
  `eleve_id`         INT           NOT NULL,
  `matiere_id`       INT           NOT NULL,
  `periode_id`       INT           NOT NULL,
  `saisie_par`       INT           NOT NULL,
  `note`             DECIMAL(4,2)  NOT NULL,
  `note_sur`         DECIMAL(4,2)  NOT NULL DEFAULT 20.00,
  `commentaire`      VARCHAR(500)  DEFAULT NULL,
  `type_evaluation`  ENUM('controle','devoir','examen','oral','autre') DEFAULT 'controle',
  `date_evaluation`  DATE          DEFAULT NULL,
  `created_at`       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_note_eleve_periode` (`eleve_id`, `periode_id`),
  CONSTRAINT `fk_note_ecole`   FOREIGN KEY (`ecole_id`)   REFERENCES `ecoles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_note_eleve`   FOREIGN KEY (`eleve_id`)   REFERENCES `eleves` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_note_matiere` FOREIGN KEY (`matiere_id`) REFERENCES `matieres` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_note_periode` FOREIGN KEY (`periode_id`) REFERENCES `periodes_evaluation` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_note_saisie`  FOREIGN KEY (`saisie_par`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Frais de scolarité mensuels
CREATE TABLE IF NOT EXISTS `frais_scolarite` (
  `id`              INT AUTO_INCREMENT PRIMARY KEY,
  `ecole_id`        INT            NOT NULL,
  `eleve_id`        INT            NOT NULL,
  `annee_scolaire`  VARCHAR(20)    NOT NULL,
  `mois`            TINYINT        NOT NULL COMMENT '1=Jan à 12=Déc',
  `montant_du`      DECIMAL(10,2)  NOT NULL,
  `montant_paye`    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
  `statut`          ENUM('non_paye','partiel','paye') DEFAULT 'non_paye',
  `date_paiement`   DATE           DEFAULT NULL,
  `confirme_par`    INT            DEFAULT NULL,
  `note_admin`      VARCHAR(500)   DEFAULT NULL,
  `created_at`      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_frais` (`eleve_id`, `annee_scolaire`, `mois`),
  CONSTRAINT `fk_frais_ecole`   FOREIGN KEY (`ecole_id`)    REFERENCES `ecoles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_frais_eleve`   FOREIGN KEY (`eleve_id`)    REFERENCES `eleves` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_frais_confirm` FOREIGN KEY (`confirme_par`) REFERENCES `utilisateurs` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
