<?php
/**
 * POST /api/auth/deconnexion
 * Invalidation côté client — le JWT est stateless, on efface juste le FCM token
 */

$payload = exigerAuth();
$pdo = getDB();

// Effacer le FCM token pour ne plus recevoir de notifications
$pdo->prepare("UPDATE utilisateurs SET fcm_token = NULL WHERE id = ?")->execute([$payload['user_id']]);

repondreSucces(null, 'Déconnexion réussie.');
