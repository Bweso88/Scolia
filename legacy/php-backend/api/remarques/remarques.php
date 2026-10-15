<?php
/**
 * GET/POST /api/remarques[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET') {
    $page   = max(1, (int) ($_GET['page'] ?? 1));
    $where  = "r.ecole_id = ?";
    $params = [$eid];

    if ($payload['role'] === 'parent') {
        $where .= " AND r.eleve_id IN (
            SELECT dp.eleve_id FROM dossiers_parents dp
            WHERE dp.parent_id = ? AND dp.actif = TRUE
        )";
        $params[] = $payload['user_id'];
    }

    if ($payload['role'] === 'teacher') {
        $cl = $pdo->prepare("SELECT id FROM classes WHERE enseignant_id = ? AND ecole_id = ?");
        $cl->execute([$payload['user_id'], $eid]);
        $ma_classe = $cl->fetch();
        if ($ma_classe) { $where .= " AND r.eleve_id IN (SELECT id FROM eleves WHERE classe_id = ?)"; $params[] = $ma_classe['id']; }
    }

    $result = paginer(
        $pdo,
        "SELECT COUNT(*) FROM remarques r WHERE $where",
        "SELECT r.id, r.categorie, r.priorite, r.message, r.created_at,
                e.prenom AS eleve_prenom, e.nom AS eleve_nom,
                u.prenom AS auteur_prenom, u.nom AS auteur_nom, u.role AS auteur_role
         FROM remarques r
         JOIN eleves e ON e.id = r.eleve_id
         JOIN utilisateurs u ON u.id = r.auteur_id
         WHERE $where ORDER BY r.created_at DESC",
        $params, $page
    );
    repondreJson($result);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin', 'teacher']);
    $corps = corpsRequete();
    exigerChamps($corps, ['eleve_id', 'message']);

    // Vérifier que l'élève appartient à cette école
    $ce = $pdo->prepare("SELECT id FROM eleves WHERE id = ? AND ecole_id = ?");
    $ce->execute([$corps['eleve_id'], $eid]);
    if (!$ce->fetch()) repondreErreur("Élève introuvable.", 404);

    $stmt = $pdo->prepare("
        INSERT INTO remarques (ecole_id, auteur_id, eleve_id, categorie, priorite, message)
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $eid, $payload['user_id'], $corps['eleve_id'],
        $corps['categorie'] ?? 'autre',
        $corps['priorite']  ?? 'info',
        $corps['message'],
    ]);
    $rq_id = (int) $pdo->lastInsertId();

    // Récupérer le prénom de l'élève
    $el = $pdo->prepare("SELECT prenom, nom FROM eleves WHERE id = ?");
    $el->execute([$corps['eleve_id']]);
    $eleve = $el->fetch();

    $titre = '📝 Remarque — ' . $eleve['prenom'] . ' ' . $eleve['nom'];
    $corps_notif = mb_substr($corps['message'], 0, 100);
    notifierParents($pdo, $eid, (int)$corps['eleve_id'], $titre, $corps_notif, 'remarque', $rq_id);

    repondreJson(['id' => $rq_id, 'message' => 'Remarque créée.'], 201);
}
