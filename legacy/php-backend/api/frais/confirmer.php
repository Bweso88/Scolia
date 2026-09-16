<?php
/**
 * PUT /api/frais/{id}/confirmer
 * Admin confirme le paiement
 */

$payload = exigerAuth();
exigerRole($payload, ['super_admin', 'school_admin']);
$pdo = getDB();
$id  = (int) ROUTE_ID;
$eid = $payload['ecole_id'];

$corps = corpsRequete();

// Vérifier l'existence et l'appartenance
$stmt = $pdo->prepare("
    SELECT fs.id, fs.eleve_id, fs.mois, fs.montant_du, e.ecole_id
    FROM frais_scolarite fs
    JOIN eleves e ON e.id = fs.eleve_id
    WHERE fs.id = ? AND e.ecole_id = ?
");
$stmt->execute([$id, $eid]);
$frais = $stmt->fetch();
if (!$frais) repondreErreur("Frais introuvable.", 404);

$montant_paye = (float) ($corps['montant_paye'] ?? $frais['montant_du']);
$statut = $montant_paye >= $frais['montant_du'] ? 'paye' : 'partiel';

$pdo->prepare("
    UPDATE frais_scolarite
    SET montant_paye = ?, statut = ?, date_paiement = ?, confirme_par = ?, note_admin = ?
    WHERE id = ?
")->execute([
    $montant_paye, $statut,
    $corps['date_paiement'] ?? date('Y-m-d'),
    $payload['user_id'],
    $corps['note_admin'] ?? null,
    $id,
]);

// Notifier le parent
$el = $pdo->prepare("SELECT prenom, nom FROM eleves WHERE id = ?");
$el->execute([$frais['eleve_id']]);
$eleve = $el->fetch();

$mois_noms = ['','Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
$titre = '✅ Paiement confirmé — ' . $mois_noms[$frais['mois']];
$corps_n = "Paiement de {$eleve['prenom']} {$eleve['nom']} : " . number_format($montant_paye, 0, ',', ' ') . ' FCFA';
notifierParents($pdo, $eid, (int)$frais['eleve_id'], $titre, $corps_n, 'frais', $id);

repondreSucces(null, 'Paiement confirmé.');
