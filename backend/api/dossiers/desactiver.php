<?php
/**
 * PUT /api/dossiers/{id}/desactiver
 */

$payload = exigerAuth();
exigerRole($payload, ['super_admin', 'school_admin']);
$pdo = getDB();
$id  = (int) ROUTE_ID;
$eid = $payload['ecole_id'];

$stmt = $pdo->prepare("
    SELECT dp.id FROM dossiers_parents dp
    JOIN eleves el ON el.id = dp.eleve_id
    WHERE dp.id = ? AND el.ecole_id = ?
");
$stmt->execute([$id, $eid]);
if (!$stmt->fetch()) repondreErreur("Dossier introuvable.", 404);

$pdo->prepare("UPDATE dossiers_parents SET actif = FALSE WHERE id = ?")->execute([$id]);
repondreSucces(null, 'Dossier désactivé.');
