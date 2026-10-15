<?php
/**
 * SCOLIA — Envoi de notifications push via Firebase Cloud Messaging (FCM v1)
 */

define('FCM_SERVER_KEY', getenv('FCM_SERVER_KEY') ?: '');
define('FCM_PROJECT_ID', getenv('FCM_PROJECT_ID') ?: '');

function envoyerNotificationFCM(string $fcm_token, string $titre, string $corps, array $data = []): bool {
    if (empty(FCM_SERVER_KEY) || empty($fcm_token)) return false;

    $payload = [
        'message' => [
            'token'        => $fcm_token,
            'notification' => ['title' => $titre, 'body' => $corps],
            'data'         => array_map('strval', $data),
            'android'      => ['priority' => 'high'],
            'apns'         => ['payload' => ['aps' => ['sound' => 'default']]],
        ],
    ];

    $ch = curl_init('https://fcm.googleapis.com/v1/projects/' . FCM_PROJECT_ID . '/messages:send');
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . FCM_SERVER_KEY,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS     => json_encode($payload),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 10,
    ]);
    $reponse = curl_exec($ch);
    $code    = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $code === 200;
}

function notifierParents(PDO $pdo, int $ecole_id, int $eleve_id, string $titre, string $corps, string $type, int $reference_id = 0): void {
    $stmt = $pdo->prepare("
        SELECT u.id, u.fcm_token
        FROM utilisateurs u
        JOIN dossiers_parents dp ON dp.parent_id = u.id
        WHERE dp.eleve_id = ? AND dp.actif = TRUE AND u.ecole_id = ?
          AND (dp.date_expiration IS NULL OR dp.date_expiration >= CURDATE())
    ");
    $stmt->execute([$eleve_id, $ecole_id]);
    $parents = $stmt->fetchAll();

    foreach ($parents as $parent) {
        // Sauvegarder en base
        $ins = $pdo->prepare("
            INSERT INTO notifications (ecole_id, destinataire_id, titre, corps, type, reference_id)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $ins->execute([$ecole_id, $parent['id'], $titre, $corps, $type, $reference_id]);

        // Envoyer FCM si token disponible
        if (!empty($parent['fcm_token'])) {
            envoyerNotificationFCM($parent['fcm_token'], $titre, $corps, [
                'type'         => $type,
                'reference_id' => (string) $reference_id,
                'ecole_id'     => (string) $ecole_id,
            ]);
        }
    }
}

function notifierClasseParents(PDO $pdo, int $ecole_id, int $classe_id, string $titre, string $corps, string $type, int $reference_id = 0): void {
    $stmt = $pdo->prepare("
        SELECT DISTINCT u.id, u.fcm_token
        FROM utilisateurs u
        JOIN dossiers_parents dp ON dp.parent_id = u.id
        JOIN eleves e ON e.id = dp.eleve_id
        WHERE e.classe_id = ? AND dp.actif = TRUE AND u.ecole_id = ?
          AND (dp.date_expiration IS NULL OR dp.date_expiration >= CURDATE())
    ");
    $stmt->execute([$classe_id, $ecole_id]);
    $parents = $stmt->fetchAll();

    foreach ($parents as $parent) {
        $ins = $pdo->prepare("
            INSERT INTO notifications (ecole_id, destinataire_id, titre, corps, type, reference_id)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $ins->execute([$ecole_id, $parent['id'], $titre, $corps, $type, $reference_id]);

        if (!empty($parent['fcm_token'])) {
            envoyerNotificationFCM($parent['fcm_token'], $titre, $corps, [
                'type'         => $type,
                'reference_id' => (string) $reference_id,
                'ecole_id'     => (string) $ecole_id,
            ]);
        }
    }
}

function notifierTousParents(PDO $pdo, int $ecole_id, string $titre, string $corps, string $type, int $reference_id = 0): void {
    $stmt = $pdo->prepare("
        SELECT id, fcm_token FROM utilisateurs
        WHERE ecole_id = ? AND role = 'parent' AND actif = TRUE
    ");
    $stmt->execute([$ecole_id]);
    $parents = $stmt->fetchAll();

    foreach ($parents as $parent) {
        $ins = $pdo->prepare("
            INSERT INTO notifications (ecole_id, destinataire_id, titre, corps, type, reference_id)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $ins->execute([$ecole_id, $parent['id'], $titre, $corps, $type, $reference_id]);

        if (!empty($parent['fcm_token'])) {
            envoyerNotificationFCM($parent['fcm_token'], $titre, $corps, [
                'type'         => $type,
                'reference_id' => (string) $reference_id,
                'ecole_id'     => (string) $ecole_id,
            ]);
        }
    }
}
