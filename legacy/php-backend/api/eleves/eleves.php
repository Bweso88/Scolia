<?php
/**
 * GET/POST/PUT /api/eleves[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET' && !$id) {
    $page      = max(1, (int) ($_GET['page'] ?? 1));
    $classe_id = $_GET['classe_id'] ?? null;
    $where     = "e.ecole_id = ? AND e.actif = TRUE";
    $params    = [$eid];

    // Enseignant : ne voit que sa classe
    if ($payload['role'] === 'teacher') {
        $cl = $pdo->prepare("SELECT id FROM classes WHERE enseignant_id = ? AND ecole_id = ?");
        $cl->execute([$payload['user_id'], $eid]);
        $ma_classe = $cl->fetch();
        if ($ma_classe) { $where .= " AND e.classe_id = ?"; $params[] = $ma_classe['id']; }
    } elseif ($classe_id) {
        $where .= " AND e.classe_id = ?"; $params[] = $classe_id;
    }

    // Parent : ne voit que ses enfants
    if ($payload['role'] === 'parent') {
        $where .= " AND EXISTS (
            SELECT 1 FROM dossiers_parents dp
            WHERE dp.eleve_id = e.id AND dp.parent_id = ? AND dp.actif = TRUE
        )";
        $params[] = $payload['user_id'];
    }

    $result = paginer(
        $pdo,
        "SELECT COUNT(*) FROM eleves e WHERE $where",
        "SELECT e.id, e.prenom, e.nom, e.matricule, e.photo_url, e.date_naissance,
                c.nom AS classe_nom, c.id AS classe_id
         FROM eleves e LEFT JOIN classes c ON c.id = e.classe_id WHERE $where ORDER BY e.nom, e.prenom",
        $params, $page
    );
    repondreJson($result);
}

if ($method === 'GET' && $id) {
    $stmt = $pdo->prepare("
        SELECT e.*, c.nom AS classe_nom
        FROM eleves e LEFT JOIN classes c ON c.id = e.classe_id
        WHERE e.id = ? AND e.ecole_id = ?
    ");
    $stmt->execute([$id, $eid]);
    $eleve = $stmt->fetch();
    if (!$eleve) repondreErreur("Élève introuvable.", 404);
    repondreJson(['eleve' => $eleve]);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    exigerChamps($corps, ['prenom', 'nom']);
    $stmt = $pdo->prepare("
        INSERT INTO eleves (ecole_id, classe_id, prenom, nom, date_naissance, matricule)
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([$eid, $corps['classe_id'] ?? null, $corps['prenom'], $corps['nom'], $corps['date_naissance'] ?? null, $corps['matricule'] ?? null]);
    repondreJson(['id' => (int) $pdo->lastInsertId(), 'message' => 'Élève créé.'], 201);
}

if ($method === 'PUT' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps  = corpsRequete();
    $champs = ['prenom', 'nom', 'classe_id', 'date_naissance', 'matricule', 'photo_url', 'actif'];
    $sets = []; $vals = [];
    foreach ($champs as $c) {
        if (array_key_exists($c, $corps)) { $sets[] = "$c = ?"; $vals[] = $corps[$c]; }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $id; $vals[] = $eid;
    $pdo->prepare("UPDATE eleves SET " . implode(', ', $sets) . " WHERE id = ? AND ecole_id = ?")->execute($vals);
    repondreSucces(null, 'Élève mis à jour.');
}
