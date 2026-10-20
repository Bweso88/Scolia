<?php
/**
 * POST /api/auth/verifier-otp
 * Vérifie le code OTP et retourne un JWT
 */

$corps = corpsRequete();
exigerChamps($corps, ['telephone', 'code', 'ecole_slug']);

$telephone  = trim($corps['telephone']);
$code       = trim($corps['code']);
$ecole_slug = trim($corps['ecole_slug']);

$pdo = getDB();

// Vérifier l'école
$stmt = $pdo->prepare("SELECT id FROM ecoles WHERE slug = ? AND actif = TRUE");
$stmt->execute([$ecole_slug]);
$ecole = $stmt->fetch();
if (!$ecole) repondreErreur("École introuvable.", 404);

// Vérifier le code OTP
$stmt = $pdo->prepare("
    SELECT id FROM otp_codes
    WHERE telephone = ? AND code = ? AND utilise = FALSE AND expires_at > NOW()
    ORDER BY created_at DESC LIMIT 1
");
$stmt->execute([$telephone, $code]);
$otp = $stmt->fetch();
if (!$otp) repondreErreur("Code OTP invalide ou expiré.", 401);

// Marquer le code comme utilisé
$pdo->prepare("UPDATE otp_codes SET utilise = TRUE WHERE id = ?")->execute([$otp['id']]);

// Récupérer l'utilisateur
$stmt = $pdo->prepare("
    SELECT id, ecole_id, telephone, prenom, nom, role, actif
    FROM utilisateurs
    WHERE telephone = ? AND ecole_id = ? AND actif = TRUE
");
$stmt->execute([$telephone, $ecole['id']]);
$utilisateur = $stmt->fetch();
if (!$utilisateur) repondreErreur("Compte inactif.", 403);

$token = creerToken($utilisateur);

repondreJson([
    'token'       => $token,
    'utilisateur' => [
        'id'       => $utilisateur['id'],
        'prenom'   => $utilisateur['prenom'],
        'nom'      => $utilisateur['nom'],
        'role'     => $utilisateur['role'],
        'ecole_id' => $utilisateur['ecole_id'],
    ],
]);
