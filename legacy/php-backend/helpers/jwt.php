<?php
/**
 * SCOLIA — Gestion des tokens JWT (implémentation manuelle, sans dépendance externe)
 */

define('JWT_SECRET', getenv('JWT_SECRET') ?: 'CHANGEZ_CE_SECRET_EN_PRODUCTION_!');
define('JWT_EXPIRATION', 60 * 60 * 24 * 30); // 30 jours

function jwtEncode(array $payload): string {
    $header  = base64url_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64url_encode(json_encode($payload));
    $sig     = base64url_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$sig";
}

function jwtDecode(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;

    [$header, $payload, $sig] = $parts;
    $expected = base64url_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));

    if (!hash_equals($expected, $sig)) return null;

    $data = json_decode(base64url_decode($payload), true);
    if (!$data || (isset($data['exp']) && $data['exp'] < time())) return null;

    return $data;
}

function creerToken(array $utilisateur): string {
    return jwtEncode([
        'user_id'  => $utilisateur['id'],
        'ecole_id' => $utilisateur['ecole_id'],
        'role'     => $utilisateur['role'],
        'iat'      => time(),
        'exp'      => time() + JWT_EXPIRATION,
    ]);
}

function tokenDepuisRequete(): ?array {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!str_starts_with($header, 'Bearer ')) return null;
    return jwtDecode(substr($header, 7));
}

function exigerAuth(): array {
    $payload = tokenDepuisRequete();
    if (!$payload) {
        http_response_code(401);
        echo json_encode(['erreur' => 'Token invalide ou manquant.']);
        exit;
    }
    return $payload;
}

function exigerRole(array $payload, array $roles_autorises): void {
    if (!in_array($payload['role'], $roles_autorises, true)) {
        http_response_code(403);
        echo json_encode(['erreur' => 'Accès interdit pour ce rôle.']);
        exit;
    }
}

function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode(string $data): string {
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
}
