<?php
/**
 * POST /api/liaison/{id}/accuser
 */

$payload = exigerAuth();
exigerRole($payload, ['parent']);
$pdo = getDB();
$id  = (int) ROUTE_ID;
$eid = $payload['ecole_id'];

$stmt = $pdo->prepare("SELECT id, necessite_ack FROM messages_liaison WHERE id = ? AND ecole_id = ?");
$stmt->execute([$id, $eid]);
$msg = $stmt->fetch();
if (!$msg) repondreErreur("Message introuvable.", 404);

$ins = $pdo->prepare("INSERT INTO accuses_reception (message_id, parent_id) VALUES (?, ?) ON CONFLICT DO NOTHING");
$ins->execute([$id, $payload['user_id']]);

repondreSucces(null, 'Accusé de réception enregistré.');
