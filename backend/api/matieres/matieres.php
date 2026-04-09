<?php
/**
 * GET/POST /api/matieres[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET') {
    $classe_id = $_GET['classe_id'] ?? null;
    $where  = "m.ecole_id = ?";
    $params = [$eid];
    if ($classe_id) { $where .= " AND (m.classe_id = ? OR m.classe_id IS NULL)"; $params[] = $classe_id; }

    $stmt = $pdo->prepare("
        SELECT m.id, m.nom, m.coefficient, m.classe_id, c.nom AS classe_nom
        FROM matieres m
        LEFT JOIN classes c ON c.id = m.classe_id
        WHERE $where ORDER BY m.nom
    ");
    $stmt->execute($params);
    repondreJson(['matieres' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['nom']);
    $stmt = $pdo->prepare("INSERT INTO matieres (ecole_id, classe_id, nom, coefficient) VALUES (?, ?, ?, ?)");
    $stmt->execute([$eid, $corps['classe_id'] ?? null, $corps['nom'], $corps['coefficient'] ?? 1.0]);
    repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Matière créée.'], 201);
}
