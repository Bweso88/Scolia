<?php
/**
 * POST /api/auth/demander-otp
 * Envoie un code OTP par SMS au numéro fourni
 */

$corps = corpsRequete();
exigerChamps($corps, ['telephone', 'ecole_slug']);

$telephone  = trim($corps['telephone']);
$ecole_slug = trim($corps['ecole_slug']);

$pdo = getDB();

// Vérifier que l'école existe et est active
$stmt = $pdo->prepare("SELECT id FROM ecoles WHERE slug = ? AND actif = TRUE");
$stmt->execute([$ecole_slug]);
$ecole = $stmt->fetch();
if (!$ecole) {
    repondreErreur("École introuvable ou inactive.", 404);
}

// Vérifier que l'utilisateur existe dans cette école
$stmt = $pdo->prepare("
    SELECT id FROM utilisateurs
    WHERE telephone = ? AND ecole_id = ? AND actif = TRUE
");
$stmt->execute([$telephone, $ecole['id']]);
if (!$stmt->fetch()) {
    repondreErreur("Numéro non reconnu dans cette école.", 404);
}

// Supprimer les anciens codes non utilisés
$pdo->prepare("DELETE FROM otp_codes WHERE telephone = ? AND utilise = FALSE")->execute([$telephone]);

// Générer un code OTP à 6 chiffres
$code       = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$expires_at = date('Y-m-d H:i:s', time() + 600); // 10 minutes

$stmt = $pdo->prepare("INSERT INTO otp_codes (telephone, code, expires_at) VALUES (?, ?, ?)");
$stmt->execute([$telephone, $code, $expires_at]);

// TODO: Intégrer un vrai fournisseur SMS (Twilio, Africa's Talking, etc.)
// Pour la phase de développement, le code est retourné dans la réponse
$reponse = ['message' => 'Code OTP envoyé par SMS.', 'expires_dans' => 600];

// En développement uniquement — retirer en production
if (getenv('APP_ENV') === 'development') {
    $reponse['debug_code'] = $code;
}

repondreJson($reponse);
