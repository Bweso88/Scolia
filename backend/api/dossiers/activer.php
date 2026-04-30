<?php
/**
 * PUT /api/dossiers/{id}/activer
 */

$payload = exigerAuth();
exigerRole($payload, ['super_admin', 'school_admin']);
$pdo = getDB();
$id  = (int) ROUTE_ID;
$eid = $payload['ecole_id'];

// Récupérer le dossier et la date de fin de scolarité de l'école
$stmt = $pdo->prepare("
    SELECT dp.id, e.date_fin_scolarite
    FROM dossiers_parents dp
    JOIN eleves el ON el.id = dp.eleve_id
    JOIN ecoles e ON e.id = el.ecole_id
    WHERE dp.id = ? AND el.ecole_id = ?
");
$stmt->execute([$id, $eid]);
$dossier = $stmt->fetch();
if (!$dossier) repondreErreur("Dossier introuvable.", 404);

$date_expiration = $dossier['date_fin_scolarite'] ?? date('Y-06-30', strtotime('+1 year'));

$pdo->prepare("
    UPDATE dossiers_parents
    SET actif = TRUE, date_activation = CURRENT_DATE, date_expiration = ?
    WHERE id = ?
")->execute([$date_expiration, $id]);

// Notifier le parent
$dp = $pdo->prepare("SELECT parent_id, eleve_id FROM dossiers_parents WHERE id = ?");
$dp->execute([$id]);
$info = $dp->fetch();

$parent = $pdo->prepare("SELECT fcm_token FROM utilisateurs WHERE id = ?");
$parent->execute([$info['parent_id']]);
$p = $parent->fetch();

$eleve = $pdo->prepare("SELECT prenom, nom FROM eleves WHERE id = ?");
$eleve->execute([$info['eleve_id']]);
$el = $eleve->fetch();

$titre = '✅ Dossier activé';
$corps = "Le dossier de {$el['prenom']} {$el['nom']} est maintenant actif.";

$ins = $pdo->prepare("
    INSERT INTO notifications (ecole_id, destinataire_id, titre, corps, type, reference_id)
    VALUES (?, ?, ?, ?, 'autre', ?)
");
$ins->execute([$eid, $info['parent_id'], $titre, $corps, $id]);

if (!empty($p['fcm_token'])) {
    envoyerNotificationFCM($p['fcm_token'], $titre, $corps, ['type' => 'dossier', 'reference_id' => (string)$id]);
}

repondreSucces(null, 'Dossier activé.');
