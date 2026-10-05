<?php
/**
 * GET/POST /api/liaison[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET' && $id) {
    $stmt = $pdo->prepare("
        SELECT ml.*, u.prenom AS auteur_prenom, u.nom AS auteur_nom, u.role AS auteur_role,
               c.nom AS classe_nom,
               (SELECT COUNT(*) FROM accuses_reception WHERE message_id = ml.id) AS nb_accuses
        FROM messages_liaison ml
        JOIN utilisateurs u ON u.id = ml.auteur_id
        LEFT JOIN classes c ON c.id = ml.classe_id
        WHERE ml.id = ? AND ml.ecole_id = ?
    ");
    $stmt->execute([$id, $eid]);
    $msg = $stmt->fetch();
    if (!$msg) repondreErreur("Message introuvable.", 404);

    // Vérifier si le parent a accusé réception
    if ($payload['role'] === 'parent') {
        $ack = $pdo->prepare("SELECT id FROM accuses_reception WHERE message_id = ? AND parent_id = ?");
        $ack->execute([$id, $payload['user_id']]);
        $msg['accuse_reception'] = (bool) $ack->fetch();
    }

    repondreJson(['message' => $msg]);
}

if ($method === 'GET') {
    $page   = max(1, (int) ($_GET['page'] ?? 1));
    $where  = "ml.ecole_id = ?";
    $params = [$eid];

    if ($payload['role'] === 'teacher') {
        $cl = $pdo->prepare("SELECT id FROM classes WHERE enseignant_id = ? AND ecole_id = ?");
        $cl->execute([$payload['user_id'], $eid]);
        $ma_classe = $cl->fetch();
        if ($ma_classe) {
            $where .= " AND (ml.classe_id = ? OR ml.classe_id IS NULL)";
            $params[] = $ma_classe['id'];
        }
    }

    if ($payload['role'] === 'parent') {
        // Parent voit les messages de la classe de ses enfants
        $where .= " AND (ml.classe_id IS NULL OR ml.classe_id IN (
            SELECT e.classe_id FROM eleves e
            JOIN dossiers_parents dp ON dp.eleve_id = e.id
            WHERE dp.parent_id = ? AND dp.actif = TRUE
        ))";
        $params[] = $payload['user_id'];
    }

    $result = paginer(
        $pdo,
        "SELECT COUNT(*) FROM messages_liaison ml WHERE $where",
        "SELECT ml.id, ml.titre, ml.contenu, ml.categorie, ml.necessite_ack, ml.created_at,
                u.prenom AS auteur_prenom, u.nom AS auteur_nom, c.nom AS classe_nom
         FROM messages_liaison ml
         JOIN utilisateurs u ON u.id = ml.auteur_id
         LEFT JOIN classes c ON c.id = ml.classe_id
         WHERE $where ORDER BY ml.created_at DESC",
        $params, $page
    );
    repondreJson($result);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin', 'teacher']);
    $corps = corpsRequete();
    exigerChamps($corps, ['contenu']);

    $stmt = $pdo->prepare("
        INSERT INTO messages_liaison (ecole_id, auteur_id, classe_id, categorie, titre, contenu, necessite_ack)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $eid, $payload['user_id'],
        $corps['classe_id'] ?? null,
        $corps['categorie'] ?? 'info',
        $corps['titre'] ?? null,
        $corps['contenu'],
        $corps['necessite_ack'] ?? false,
    ]);
    $msg_id = (int) $pdo->lastInsertId();

    // Notifier les parents
    $titre_notif = '📋 Nouveau message — ' . ($corps['titre'] ?? 'Cahier de liaison');
    $corps_notif = mb_substr($corps['contenu'], 0, 100);
    if (isset($corps['classe_id'])) {
        notifierClasseParents($pdo, $eid, (int)$corps['classe_id'], $titre_notif, $corps_notif, 'liaison', $msg_id);
    } else {
        notifierTousParents($pdo, $eid, $titre_notif, $corps_notif, 'liaison', $msg_id);
    }

    repondreJson(['id' => $msg_id, 'message' => 'Message publié.'], 201);
}
