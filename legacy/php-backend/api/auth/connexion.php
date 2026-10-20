<?php
/**
 * POST /api/auth/connexion
 * Authentification : numéro de téléphone + code d'accès (sans OTP)
 *
 * Parent  → code_dossier généré à l'activation du dossier
 * Teacher / Admin → code_acces défini par l'administrateur
 */

$corps = corpsRequete();
exigerChamps($corps, ['telephone', 'code', 'ecole_slug']);

$telephone  = trim($corps['telephone']);
$code       = strtoupper(trim($corps['code']));
$ecole_slug = trim($corps['ecole_slug']);

$pdo = getDB();

$stmt = $pdo->prepare("SELECT id FROM ecoles WHERE slug = ? AND actif = TRUE");
$stmt->execute([$ecole_slug]);
$ecole = $stmt->fetch();
if (!$ecole) repondreErreur("École introuvable ou inactive.", 404);

$stmt = $pdo->prepare("
    SELECT id, ecole_id, telephone, prenom, nom, role, actif, code_acces
    FROM utilisateurs
    WHERE telephone = ? AND ecole_id = ? AND actif = TRUE
");
$stmt->execute([$telephone, $ecole['id']]);
$utilisateur = $stmt->fetch();
if (!$utilisateur) repondreErreur("Numéro de téléphone non reconnu dans cette école.", 401);

$accesAutorise = false;

if ($utilisateur['role'] === 'parent') {
    $stmt = $pdo->prepare("
        SELECT id FROM dossiers_parents
        WHERE parent_id = ? AND UPPER(code_dossier) = ? AND actif = TRUE
    ");
    $stmt->execute([$utilisateur['id'], $code]);
    $accesAutorise = (bool) $stmt->fetch();
} else {
    $accesAutorise = (
        $utilisateur['code_acces'] !== null &&
        strtoupper($utilisateur['code_acces']) === $code
    );
}

if (!$accesAutorise) repondreErreur("Code incorrect.", 401);

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
