<?php
/**
 * GET/PUT /api/ecole
 */

$payload = exigerAuth();
$pdo = getDB();

if ($method === 'GET') {
    $stmt = $pdo->prepare("SELECT * FROM ecoles WHERE id = ?");
    $stmt->execute([$payload['ecole_id']]);
    $ecole = $stmt->fetch();
    if (!$ecole) repondreErreur("École introuvable.", 404);
    repondreJson(['ecole' => $ecole]);
}

if ($method === 'PUT') {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $corps = corpsRequete();
    $champs_autorises = ['nom','ville','telephone','email','adresse','logo_url','annee_scolaire','date_debut_scolarite','date_fin_scolarite'];
    $sets = [];
    $vals = [];
    foreach ($champs_autorises as $c) {
        if (array_key_exists($c, $corps)) {
            $sets[] = "$c = ?";
            $vals[] = $corps[$c];
        }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $payload['ecole_id'];
    $pdo->prepare("UPDATE ecoles SET " . implode(', ', $sets) . " WHERE id = ?")->execute($vals);
    repondreSucces(null, 'École mise à jour.');
}
