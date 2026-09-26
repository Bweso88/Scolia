-- ══════════════════════════════════════════════════════════════════
-- SCOLIA — Migration v2 : Modules Notes et Frais de scolarité (PostgreSQL)
-- À exécuter sur une base de données Scolia v1 existante
--   psql -U postgres -d scolia -f migration_v2.sql
-- ══════════════════════════════════════════════════════════════════

-- Matières par classe
CREATE TABLE IF NOT EXISTS matieres (
  id           SERIAL PRIMARY KEY,
  ecole_id     INTEGER      NOT NULL,
  classe_id    INTEGER      DEFAULT NULL,
  nom          VARCHAR(100) NOT NULL,
  coefficient  DECIMAL(3,1) NOT NULL DEFAULT 1.0,
  CONSTRAINT fk_mat_ecole  FOREIGN KEY (ecole_id)  REFERENCES ecoles(id)  ON DELETE CASCADE,
  CONSTRAINT fk_mat_classe FOREIGN KEY (classe_id) REFERENCES classes(id) ON DELETE SET NULL
);

-- Périodes d'évaluation (trimestres)
CREATE TABLE IF NOT EXISTS periodes_evaluation (
  id              SERIAL PRIMARY KEY,
  ecole_id        INTEGER     NOT NULL,
  nom             VARCHAR(50) NOT NULL,
  date_debut      DATE        DEFAULT NULL,
  date_fin        DATE        DEFAULT NULL,
  annee_scolaire  VARCHAR(20) DEFAULT NULL,
  CONSTRAINT fk_pe_ecole FOREIGN KEY (ecole_id) REFERENCES ecoles(id) ON DELETE CASCADE
);

-- Notes des élèves
CREATE TABLE IF NOT EXISTS notes (
  id               SERIAL PRIMARY KEY,
  ecole_id         INTEGER      NOT NULL,
  eleve_id         INTEGER      NOT NULL,
  matiere_id       INTEGER      NOT NULL,
  periode_id       INTEGER      NOT NULL,
  saisie_par       INTEGER      NOT NULL,
  note             DECIMAL(4,2) NOT NULL,
  note_sur         DECIMAL(4,2) NOT NULL DEFAULT 20.00,
  commentaire      VARCHAR(500) DEFAULT NULL,
  type_evaluation  VARCHAR(15)  DEFAULT 'controle' CHECK (type_evaluation IN ('controle','devoir','examen','oral','autre')),
  date_evaluation  DATE         DEFAULT NULL,
  created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_note_ecole   FOREIGN KEY (ecole_id)   REFERENCES ecoles(id)              ON DELETE CASCADE,
  CONSTRAINT fk_note_eleve   FOREIGN KEY (eleve_id)   REFERENCES eleves(id)              ON DELETE CASCADE,
  CONSTRAINT fk_note_matiere FOREIGN KEY (matiere_id) REFERENCES matieres(id)            ON DELETE CASCADE,
  CONSTRAINT fk_note_periode FOREIGN KEY (periode_id) REFERENCES periodes_evaluation(id) ON DELETE CASCADE,
  CONSTRAINT fk_note_saisie  FOREIGN KEY (saisie_par) REFERENCES utilisateurs(id)        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_note_eleve_periode ON notes(eleve_id, periode_id);

-- Frais de scolarité mensuels
CREATE TABLE IF NOT EXISTS frais_scolarite (
  id              SERIAL PRIMARY KEY,
  ecole_id        INTEGER       NOT NULL,
  eleve_id        INTEGER       NOT NULL,
  annee_scolaire  VARCHAR(20)   NOT NULL,
  mois            SMALLINT      NOT NULL,
  montant_du      DECIMAL(10,2) NOT NULL,
  montant_paye    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  statut          VARCHAR(15)   DEFAULT 'non_paye' CHECK (statut IN ('non_paye','partiel','paye')),
  date_paiement   DATE          DEFAULT NULL,
  confirme_par    INTEGER       DEFAULT NULL,
  note_admin      VARCHAR(500)  DEFAULT NULL,
  created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_frais         UNIQUE (eleve_id, annee_scolaire, mois),
  CONSTRAINT fk_frais_ecole   FOREIGN KEY (ecole_id)     REFERENCES ecoles(id)      ON DELETE CASCADE,
  CONSTRAINT fk_frais_eleve   FOREIGN KEY (eleve_id)     REFERENCES eleves(id)      ON DELETE CASCADE,
  CONSTRAINT fk_frais_confirm FOREIGN KEY (confirme_par) REFERENCES utilisateurs(id) ON DELETE SET NULL
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
