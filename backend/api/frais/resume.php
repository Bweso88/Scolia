<?php
/**
 * GET /api/frais/resume/{eleve_id}
 * Résumé annuel des frais d'un élève
 */

$payload  = exigerAuth();
$pdo      = getDB();
$eid      = $payload['ecole_id'];
$eleve_id = (int) ROUTE_ID;

if ($payload['role'] === 'parent') {
    $check = $pdo->prepare("
        SELECT dp.id FROM dossiers_parents dp
        WHERE dp.parent_id = ? AND dp.eleve_id = ? AND dp.actif = TRUE
    ");
    $check->execute([$payload['user_id'], $eleve_id]);
    if (!$check->fetch()) repondreErreur("Accès non autorisé.", 403);
}

$annee = $_GET['annee_scolaire'] ?? null;
$where  = "fs.eleve_id = ? AND e.ecole_id = ?";
$params = [$eleve_id, $eid];
if ($annee) { $where .= " AND fs.annee_scolaire = ?"; $params[] = $annee; }

$stmt = $pdo->prepare("
    SELECT
        SUM(fs.montant_du)   AS total_du,
        SUM(fs.montant_paye) AS total_paye,
        SUM(fs.montant_du) - SUM(fs.montant_paye) AS solde,
        COUNT(*) AS nb_mois,
        SUM(CASE WHEN fs.statut = 'paye'     THEN 1 ELSE 0 END) AS nb_payes,
        SUM(CASE WHEN fs.statut = 'partiel'  THEN 1 ELSE 0 END) AS nb_partiels,
        SUM(CASE WHEN fs.statut = 'non_paye' THEN 1 ELSE 0 END) AS nb_impayes
    FROM frais_scolarite fs
    JOIN eleves e ON e.id = fs.eleve_id
    WHERE $where
");
$stmt->execute($params);
$resume = $stmt->fetch();

repondreJson(['resume' => $resume]);
