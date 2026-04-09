<?php
/**
 * GET /api/frais/eleve/{eleve_id}
 */

$payload  = exigerAuth();
$pdo      = getDB();
$eid      = $payload['ecole_id'];
$eleve_id = (int) ROUTE_ID;

// Contrôle d'accès
if ($payload['role'] === 'parent') {
    $check = $pdo->prepare("
        SELECT dp.id FROM dossiers_parents dp
        WHERE dp.parent_id = ? AND dp.eleve_id = ? AND dp.actif = TRUE
        AND (dp.date_expiration IS NULL OR dp.date_expiration >= CURDATE())
    ");
    $check->execute([$payload['user_id'], $eleve_id]);
    if (!$check->fetch()) repondreErreur("Accès non autorisé.", 403);
}

$stmt = $pdo->prepare("
    SELECT fs.id, fs.mois, fs.annee_scolaire, fs.montant_du, fs.montant_paye,
           fs.statut, fs.date_paiement, fs.note_admin
    FROM frais_scolarite fs
    JOIN eleves e ON e.id = fs.eleve_id
    WHERE fs.eleve_id = ? AND e.ecole_id = ?
    ORDER BY fs.annee_scolaire DESC, fs.mois ASC
");
$stmt->execute([$eleve_id, $eid]);
repondreJson(['frais' => $stmt->fetchAll()]);
