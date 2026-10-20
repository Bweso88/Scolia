<?php
/**
 * PUT /api/notifications/{id}/lire
 */

$payload = exigerAuth();
$pdo = getDB();
$id  = (int) ROUTE_ID;

$pdo->prepare("
    UPDATE notifications SET lue = TRUE
    WHERE id = ? AND destinataire_id = ? AND ecole_id = ?
")->execute([$id, $payload['user_id'], $payload['ecole_id']]);

repondreSucces(null, 'Notification marquée comme lue.');
