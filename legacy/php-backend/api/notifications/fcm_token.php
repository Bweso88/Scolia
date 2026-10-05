<?php
/**
 * POST /api/notifications/fcm-token
 */

$payload = exigerAuth();
$corps = corpsRequete();
exigerChamps($corps, ['fcm_token']);

$pdo = getDB();
$pdo->prepare("UPDATE utilisateurs SET fcm_token = ? WHERE id = ?")->execute([$corps['fcm_token'], $payload['user_id']]);

repondreSucces(null, 'Token FCM enregistré.');
