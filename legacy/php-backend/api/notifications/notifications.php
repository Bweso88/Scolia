<?php
/**
 * GET /api/notifications
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];

$page = max(1, (int) ($_GET['page'] ?? 1));
$non_lues = $_GET['non_lues'] ?? null;

$where  = "n.ecole_id = ? AND n.destinataire_id = ?";
$params = [$eid, $payload['user_id']];
if ($non_lues === '1') { $where .= " AND n.lue = FALSE"; }

$result = paginer(
    $pdo,
    "SELECT COUNT(*) FROM notifications n WHERE $where",
    "SELECT n.id, n.titre, n.corps, n.type, n.reference_id, n.lue, n.created_at
     FROM notifications n WHERE $where ORDER BY n.created_at DESC",
    $params, $page
);

// Ajouter le compteur non lues
$nb = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE ecole_id = ? AND destinataire_id = ? AND lue = FALSE");
$nb->execute([$eid, $payload['user_id']]);
$result['nb_non_lues'] = (int) $nb->fetchColumn();

repondreJson($result);
