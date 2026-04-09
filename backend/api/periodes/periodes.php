<?php
/**
 * GET/POST /api/periodes[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];

if ($method === 'GET') {
    $stmt = $pdo->prepare("SELECT * FROM periodes_evaluation WHERE ecole_id = ? ORDER BY date_debut");
    $stmt->execute([$eid]);
    repondreJson(['periodes' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['nom']);
    $stmt = $pdo->prepare("INSERT INTO periodes_evaluation (ecole_id, nom, date_debut, date_fin, annee_scolaire) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$eid, $corps['nom'], $corps['date_debut'] ?? null, $corps['date_fin'] ?? null, $corps['annee_scolaire'] ?? null]);
    repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Période créée.'], 201);
}
