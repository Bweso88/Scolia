<?php
/**
 * PUT /api/notifications/lire-tout
 */

$payload = exigerAuth();
$pdo = getDB();

$pdo->prepare("
    UPDATE notifications SET lue = TRUE
    WHERE destinataire_id = ? AND ecole_id = ? AND lue = FALSE
")->execute([$payload['user_id'], $payload['ecole_id']]);

repondreSucces(null, 'Toutes les notifications ont été marquées comme lues.');
