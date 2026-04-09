<?php
/**
 * GET/POST/PUT/DELETE /api/evenements[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET') {
    $futur = $_GET['futur'] ?? '0';
    $where  = "ecole_id = ?";
    $params = [$eid];
    if ($futur === '1') { $where .= " AND date_debut >= CURDATE()"; }
    $stmt = $pdo->prepare("
        SELECT e.id, e.titre, e.description, e.date_debut, e.heure_debut, e.lieu, e.type, e.created_at,
               u.prenom AS auteur_prenom, u.nom AS auteur_nom
        FROM evenements e
        JOIN utilisateurs u ON u.id = e.auteur_id
        WHERE $where ORDER BY e.date_debut ASC
    ");
    $stmt->execute($params);
    repondreJson(['evenements' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['titre', 'date_debut']);
    $stmt = $pdo->prepare("
        INSERT INTO evenements (ecole_id, auteur_id, titre, description, date_debut, heure_debut, lieu, type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $eid, $payload['user_id'], $corps['titre'],
        $corps['description'] ?? null, $corps['date_debut'],
        $corps['heure_debut'] ?? null, $corps['lieu'] ?? null,
        $corps['type'] ?? 'autre',
    ]);
    $ev_id = (int) $pdo->lastInsertId();

    notifierTousParents($pdo, $eid,
        '📅 ' . $corps['titre'],
        ($corps['description'] ?? '') ? mb_substr($corps['description'], 0, 100) : $corps['date_debut'],
        'evenement', $ev_id
    );

    repondreJson(['id' => $ev_id, 'message' => 'Événement créé.'], 201);
}

if ($method === 'PUT' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps  = corpsRequete();
    $champs = ['titre', 'description', 'date_debut', 'heure_debut', 'lieu', 'type'];
    $sets = []; $vals = [];
    foreach ($champs as $c) {
        if (array_key_exists($c, $corps)) { $sets[] = "$c = ?"; $vals[] = $corps[$c]; }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $id; $vals[] = $eid;
    $pdo->prepare("UPDATE evenements SET " . implode(', ', $sets) . " WHERE id = ? AND ecole_id = ?")->execute($vals);
    repondreSucces(null, 'Événement mis à jour.');
}

if ($method === 'DELETE' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $pdo->prepare("DELETE FROM evenements WHERE id = ? AND ecole_id = ?")->execute([$id, $eid]);
    repondreSucces(null, 'Événement supprimé.');
}
