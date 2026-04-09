<?php
/**
 * POST /api/remarques/{id}/lire
 */

$payload = exigerAuth();
exigerRole($payload, ['parent']);
$pdo = getDB();
$id  = (int) ROUTE_ID;

$stmt = $pdo->prepare("SELECT id FROM remarques WHERE id = ? AND ecole_id = ?");
$stmt->execute([$id, $payload['ecole_id']]);
if (!$stmt->fetch()) repondreErreur("Remarque introuvable.", 404);

$ins = $pdo->prepare("INSERT IGNORE INTO remarques_lues (remarque_id, parent_id) VALUES (?, ?)");
$ins->execute([$id, $payload['user_id']]);

repondreSucces(null, 'Remarque marquée comme lue.');
