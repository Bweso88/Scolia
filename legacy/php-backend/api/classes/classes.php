<?php
/**
 * GET/POST/PUT /api/classes[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET') {
    $stmt = $pdo->prepare("
        SELECT c.id, c.nom, c.niveau, c.annee_scolaire, c.enseignant_id,
               u.prenom AS ens_prenom, u.nom AS ens_nom,
               COUNT(e.id) AS nb_eleves
        FROM classes c
        LEFT JOIN utilisateurs u ON u.id = c.enseignant_id
        LEFT JOIN eleves e ON e.classe_id = c.id AND e.actif = TRUE
        WHERE c.ecole_id = ?
        GROUP BY c.id ORDER BY c.nom
    ");
    $stmt->execute([$eid]);
    repondreJson(['classes' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['nom']);
    $stmt = $pdo->prepare("INSERT INTO classes (ecole_id, nom, niveau, annee_scolaire, enseignant_id) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$eid, $corps['nom'], $corps['niveau'] ?? null, $corps['annee_scolaire'] ?? null, $corps['enseignant_id'] ?? null]);
    repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Classe créée.'], 201);
}

if ($method === 'PUT' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps  = corpsRequete();
    $champs = ['nom', 'niveau', 'annee_scolaire', 'enseignant_id'];
    $sets = []; $vals = [];
    foreach ($champs as $c) {
        if (array_key_exists($c, $corps)) { $sets[] = "$c = ?"; $vals[] = $corps[$c]; }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $id; $vals[] = $eid;
    $pdo->prepare("UPDATE classes SET " . implode(', ', $sets) . " WHERE id = ? AND ecole_id = ?")->execute($vals);
    repondreSucces(null, 'Classe mise à jour.');
}
