<?php
/**
 * SCOLIA — Routeur central de l'API REST
 */

// ─── CORS ─────────────────────────────────────────────────────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ─── Chargement des helpers ───────────────────────────────────────────────────
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/helpers/jwt.php';
require_once __DIR__ . '/helpers/response.php';
require_once __DIR__ . '/helpers/fcm.php';

// ─── Routage ──────────────────────────────────────────────────────────────────
$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri    = rtrim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'];

// Supprimer le préfixe /api si présent
$uri = preg_replace('#^/api#', '', $uri);

// Extraire les segments et les paramètres dynamiques
$segments = array_values(array_filter(explode('/', $uri)));

function router(string $method, string $uri, array $segments): void {
    $s = $segments;
    $n = count($s);

    // ── Auth ──────────────────────────────────────────────────────────────────
    if ($n >= 2 && $s[0] === 'auth') {
        switch ($s[1]) {
            case 'demander-otp':  require __DIR__ . '/api/auth/demander_otp.php';  return;
            case 'verifier-otp':  require __DIR__ . '/api/auth/verifier_otp.php';  return;
            case 'deconnexion':   require __DIR__ . '/api/auth/deconnexion.php';   return;
            case 'profil':        require __DIR__ . '/api/auth/profil.php';        return;
        }
    }

    // ── École ─────────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'ecole') {
        if ($n === 2 && $s[1] === 'stats') { require __DIR__ . '/api/ecole/stats.php'; return; }
        require __DIR__ . '/api/ecole/ecole.php'; return;
    }

    // ── Utilisateurs ─────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'utilisateurs') {
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/utilisateurs/utilisateurs.php'; return;
    }

    // ── Élèves ────────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'eleves') {
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/eleves/eleves.php'; return;
    }

    // ── Dossiers ──────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'dossiers') {
        if ($n === 3 && $s[2] === 'activer')    { define('ROUTE_ID', $s[1]); require __DIR__ . '/api/dossiers/activer.php'; return; }
        if ($n === 3 && $s[2] === 'desactiver') { define('ROUTE_ID', $s[1]); require __DIR__ . '/api/dossiers/desactiver.php'; return; }
        require __DIR__ . '/api/dossiers/dossiers.php'; return;
    }

    // ── Classes ───────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'classes') {
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/classes/classes.php'; return;
    }

    // ── Liaison ───────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'liaison') {
        if ($n === 3 && $s[2] === 'accuser') { define('ROUTE_ID', $s[1]); require __DIR__ . '/api/liaison/accuser.php'; return; }
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/liaison/liaison.php'; return;
    }

    // ── Remarques ─────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'remarques') {
        if ($n === 3 && $s[2] === 'lire') { define('ROUTE_ID', $s[1]); require __DIR__ . '/api/remarques/lire.php'; return; }
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/remarques/remarques.php'; return;
    }

    // ── Événements ────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'evenements') {
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/evenements/evenements.php'; return;
    }

    // ── Notes ─────────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'notes') {
        if ($n === 4 && $s[1] === 'bulletin') {
            define('ROUTE_ELEVE_ID',  $s[2]);
            define('ROUTE_PERIODE_ID', $s[3]);
            require __DIR__ . '/api/notes/bulletin.php'; return;
        }
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/notes/notes.php'; return;
    }

    // ── Matières ──────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'matieres') {
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/matieres/matieres.php'; return;
    }

    // ── Périodes ──────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'periodes') {
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/periodes/periodes.php'; return;
    }

    // ── Frais ─────────────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'frais') {
        if ($n === 3 && $s[1] === 'eleve')  { define('ROUTE_ID', $s[2]); require __DIR__ . '/api/frais/par_eleve.php'; return; }
        if ($n === 3 && $s[1] === 'resume') { define('ROUTE_ID', $s[2]); require __DIR__ . '/api/frais/resume.php'; return; }
        if ($n === 3 && $s[2] === 'confirmer') { define('ROUTE_ID', $s[1]); require __DIR__ . '/api/frais/confirmer.php'; return; }
        define('ROUTE_ID', $s[1] ?? null);
        require __DIR__ . '/api/frais/frais.php'; return;
    }

    // ── Notifications ─────────────────────────────────────────────────────────
    if ($n >= 1 && $s[0] === 'notifications') {
        if ($n === 2 && $s[1] === 'lire-tout')  { require __DIR__ . '/api/notifications/lire_tout.php'; return; }
        if ($n === 2 && $s[1] === 'fcm-token')  { require __DIR__ . '/api/notifications/fcm_token.php'; return; }
        if ($n === 3 && $s[2] === 'lire')       { define('ROUTE_ID', $s[1]); require __DIR__ . '/api/notifications/lire.php'; return; }
        require __DIR__ . '/api/notifications/notifications.php'; return;
    }

    // ── 404 ───────────────────────────────────────────────────────────────────
    http_response_code(404);
    echo json_encode(['erreur' => 'Route introuvable : ' . $uri]);
}

router($method, $uri, $segments);
