<?php
/**
 * GET/POST /api/dossiers
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];

if ($method === 'GET') {
    if ($payload['role'] === 'parent') {
        $stmt = $pdo->prepare("
            SELECT dp.id, dp.actif, dp.date_activation, dp.date_expiration,
                   e.id AS eleve_id, e.prenom, e.nom, e.photo_url, e.matricule,
                   c.nom AS classe_nom
            FROM dossiers_parents dp
            JOIN eleves e ON e.id = dp.eleve_id
            LEFT JOIN classes c ON c.id = e.classe_id
            WHERE dp.parent_id = ? AND e.ecole_id = ?
            ORDER BY e.nom, e.prenom
        ");
        $stmt->execute([$payload['user_id'], $eid]);
    } else {
        exigerRole($payload, ['super_admin', 'school_admin', 'teacher']);
        $stmt = $pdo->prepare("
            SELECT dp.id, dp.actif, dp.date_activation, dp.date_expiration,
                   e.prenom AS eleve_prenom, e.nom AS eleve_nom,
                   u.prenom AS parent_prenom, u.nom AS parent_nom, u.telephone
            FROM dossiers_parents dp
            JOIN eleves e ON e.id = dp.eleve_id
            JOIN utilisateurs u ON u.id = dp.parent_id
            WHERE e.ecole_id = ?
            ORDER BY e.nom, u.nom
        ");
        $stmt->execute([$eid]);
    }
    repondreJson(['dossiers' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['parent_id', 'eleve_id']);

    // Vérifier que le parent et l'élève appartiennent à cette école
    $cp = $pdo->prepare("SELECT id FROM utilisateurs WHERE id = ? AND ecole_id = ? AND role = 'parent'");
    $cp->execute([$corps['parent_id'], $eid]);
    if (!$cp->fetch()) repondreErreur("Parent introuvable.", 404);

    $ce = $pdo->prepare("SELECT id FROM eleves WHERE id = ? AND ecole_id = ?");
    $ce->execute([$corps['eleve_id'], $eid]);
    if (!$ce->fetch()) repondreErreur("Élève introuvable.", 404);

    $stmt = $pdo->prepare("INSERT INTO dossiers_parents (parent_id, eleve_id) VALUES (?, ?)");
    try {
        $stmt->execute([$corps['parent_id'], $corps['eleve_id']]);
        repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Dossier créé.'], 201);
    } catch (PDOException $e) {
        repondreErreur("Ce dossier existe déjà.", 409);
    }
}
