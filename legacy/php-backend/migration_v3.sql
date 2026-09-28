-- ══════════════════════════════════════════════════════════════════
-- SCOLIA — Migration v3 : Authentification par code (sans OTP)
-- Remplace le système OTP par phone + code d'accès personnel
--   psql -U postgres -d scolia -f migration_v3.sql
-- ══════════════════════════════════════════════════════════════════

-- Code d'accès personnel pour les enseignants et admins
ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS code_acces VARCHAR(10) DEFAULT NULL;

-- Code dossier unique généré par l'école pour chaque parent
ALTER TABLE dossiers_parents
  ADD COLUMN IF NOT EXISTS code_dossier VARCHAR(10) DEFAULT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_code_dossier
  ON dossiers_parents(code_dossier)
  WHERE code_dossier IS NOT NULL;
