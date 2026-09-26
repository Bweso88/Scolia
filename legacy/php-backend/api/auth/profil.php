<?php
/**
 * GET /api/auth/profil
 * Retourne le profil de l'utilisateur connecté avec les infos de son école
 */

$payload = exigerAuth();
$pdo = getDB();

$stmt = $pdo->prepare("
    SELECT u.id, u.prenom, u.nom, u.telephone, u.role, u.actif, u.ecole_id,
           e.nom AS ecole_nom, e.slug AS ecole_slug, e.logo_url, e.annee_scolaire,
           e.plan, e.date_fin_abonnement
    FROM utilisateurs u
    JOIN ecoles e ON e.id = u.ecole_id
    WHERE u.id = ?
");
$stmt->execute([$payload['user_id']]);
$profil = $stmt->fetch();

if (!$profil) repondreErreur("Utilisateur introuvable.", 404);

repondreJson(['profil' => $profil]);
