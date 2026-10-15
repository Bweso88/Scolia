<?php
/**
 * GET/POST/PUT/DELETE /api/utilisateurs[/{id}]
 */

$payload = exigerAuth();
exigerRole($payload, ['super_admin', 'school_admin']);
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET' && !$id) {
    $page     = max(1, (int) ($_GET['page'] ?? 1));
    $role     = $_GET['role'] ?? null;
    $where    = "ecole_id = ?";
    $params   = [$eid];
    if ($role) { $where .= " AND role = ?"; $params[] = $role; }

    $result = paginer(
        $pdo,
        "SELECT COUNT(*) FROM utilisateurs WHERE $where",
        "SELECT id, prenom, nom, telephone, role, actif, created_at FROM utilisateurs WHERE $where ORDER BY nom, prenom",
        $params, $page
    );
    repondreJson($result);
}

if ($method === 'GET' && $id) {
    $stmt = $pdo->prepare("SELECT id, prenom, nom, telephone, role, actif, created_at FROM utilisateurs WHERE id = ? AND ecole_id = ?");
    $stmt->execute([$id, $eid]);
    $u = $stmt->fetch();
    if (!$u) repondreErreur("Utilisateur introuvable.", 404);
    repondreJson(['utilisateur' => $u]);
}

if ($method === 'POST') {
    $corps = corpsRequete();
    exigerChamps($corps, ['telephone', 'role']);
    $roles_valides = ['school_admin', 'teacher', 'parent'];
    if (!in_array($corps['role'], $roles_valides, true)) repondreErreur("Rôle invalide.");

    // Vérifier doublon
    $check = $pdo->prepare("SELECT id FROM utilisateurs WHERE telephone = ? AND ecole_id = ?");
    $check->execute([$corps['telephone'], $eid]);
    if ($check->fetch()) repondreErreur("Ce numéro existe déjà dans cette école.", 409);

    $stmt = $pdo->prepare("
        INSERT INTO utilisateurs (ecole_id, telephone, prenom, nom, role)
        VALUES (?, ?, ?, ?, ?)
    ");
    $stmt->execute([$eid, $corps['telephone'], $corps['prenom'] ?? null, $corps['nom'] ?? null, $corps['role']]);
    repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Utilisateur créé.'], 201);
}

if ($method === 'PUT' && $id) {
    $corps = corpsRequete();
    $champs = ['prenom', 'nom', 'telephone', 'actif'];
    $sets = []; $vals = [];
    foreach ($champs as $c) {
        if (array_key_exists($c, $corps)) { $sets[] = "$c = ?"; $vals[] = $corps[$c]; }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $id; $vals[] = $eid;
    $pdo->prepare("UPDATE utilisateurs SET " . implode(', ', $sets) . " WHERE id = ? AND ecole_id = ?")->execute($vals);
    repondreSucces(null, 'Utilisateur mis à jour.');
}

if ($method === 'DELETE' && $id) {
    $pdo->prepare("UPDATE utilisateurs SET actif = FALSE WHERE id = ? AND ecole_id = ?")->execute([$id, $eid]);
    repondreSucces(null, 'Utilisateur désactivé.');
}
