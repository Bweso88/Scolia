<?php
/**
 * GET/POST/PUT /api/frais[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET') {
    $page   = max(1, (int) ($_GET['page'] ?? 1));
    $mois   = $_GET['mois']   ?? null;
    $statut = $_GET['statut'] ?? null;
    $where  = "e.ecole_id = ?";
    $params = [$eid];

    if ($payload['role'] === 'parent') {
        $where .= " AND fs.eleve_id IN (
            SELECT dp.eleve_id FROM dossiers_parents dp
            WHERE dp.parent_id = ? AND dp.actif = TRUE
            AND (dp.date_expiration IS NULL OR dp.date_expiration >= CURDATE())
        )";
        $params[] = $payload['user_id'];
    }

    if ($mois)   { $where .= " AND fs.mois = ?";   $params[] = $mois; }
    if ($statut) { $where .= " AND fs.statut = ?"; $params[] = $statut; }

    $result = paginer(
        $pdo,
        "SELECT COUNT(*) FROM frais_scolarite fs JOIN eleves e ON e.id = fs.eleve_id WHERE $where",
        "SELECT fs.id, fs.mois, fs.annee_scolaire, fs.montant_du, fs.montant_paye, fs.statut,
                fs.date_paiement, fs.note_admin, fs.updated_at,
                e.prenom AS eleve_prenom, e.nom AS eleve_nom,
                u.prenom AS confirme_prenom, u.nom AS confirme_nom
         FROM frais_scolarite fs
         JOIN eleves e ON e.id = fs.eleve_id
         LEFT JOIN utilisateurs u ON u.id = fs.confirme_par
         WHERE $where ORDER BY fs.annee_scolaire DESC, fs.mois ASC",
        $params, $page
    );
    repondreJson($result);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['eleve_id', 'annee_scolaire', 'mois', 'montant_du']);

    if ($corps['mois'] < 1 || $corps['mois'] > 12) repondreErreur("Mois invalide (1-12).");

    $ce = $pdo->prepare("SELECT id FROM eleves WHERE id = ? AND ecole_id = ?");
    $ce->execute([$corps['eleve_id'], $eid]);
    if (!$ce->fetch()) repondreErreur("Élève introuvable.", 404);

    $stmt = $pdo->prepare("
        INSERT INTO frais_scolarite (ecole_id, eleve_id, annee_scolaire, mois, montant_du)
        VALUES (?, ?, ?, ?, ?)
    ");
    try {
        $stmt->execute([$eid, $corps['eleve_id'], $corps['annee_scolaire'], $corps['mois'], $corps['montant_du']]);
        repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Frais créé.'], 201);
    } catch (PDOException $e) {
        repondreErreur("Des frais existent déjà pour cet élève ce mois-ci.", 409);
    }
}

if ($method === 'PUT' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps  = corpsRequete();
    $champs = ['montant_du', 'montant_paye', 'statut', 'date_paiement', 'note_admin'];
    $sets = []; $vals = [];
    foreach ($champs as $c) {
        if (array_key_exists($c, $corps)) { $sets[] = "$c = ?"; $vals[] = $corps[$c]; }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $id; $vals[] = $eid;

    // Vérifier appartenance à l'école
    $check = $pdo->prepare("SELECT fs.id FROM frais_scolarite fs JOIN eleves e ON e.id = fs.eleve_id WHERE fs.id = ? AND e.ecole_id = ?");
    $check->execute([$id, $eid]);
    if (!$check->fetch()) repondreErreur("Frais introuvable.", 404);

    $pdo->prepare("UPDATE frais_scolarite SET " . implode(', ', $sets) . " WHERE id = ?")->execute(array_merge(array_slice($vals, 0, -1), [$id]));
    repondreSucces(null, 'Frais mis à jour.');
}
