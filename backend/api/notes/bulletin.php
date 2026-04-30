<?php
/**
 * GET /api/notes/bulletin/{eleve_id}/{periode_id}
 * Retourne le bulletin complet d'un élève pour une période donnée
 */

$payload   = exigerAuth();
$pdo       = getDB();
$eid       = $payload['ecole_id'];
$eleve_id  = (int) ROUTE_ELEVE_ID;
$periode_id = (int) ROUTE_PERIODE_ID;

// Vérification d'accès
if ($payload['role'] === 'parent') {
    $check = $pdo->prepare("
        SELECT dp.id FROM dossiers_parents dp
        WHERE dp.parent_id = ? AND dp.eleve_id = ? AND dp.actif = TRUE
        AND (dp.date_expiration IS NULL OR dp.date_expiration >= CURRENT_DATE)
    ");
    $check->execute([$payload['user_id'], $eleve_id]);
    if (!$check->fetch()) repondreErreur("Accès non autorisé à ce dossier.", 403);
}

// Infos de l'élève
$el = $pdo->prepare("SELECT e.*, c.nom AS classe_nom FROM eleves e LEFT JOIN classes c ON c.id = e.classe_id WHERE e.id = ? AND e.ecole_id = ?");
$el->execute([$eleve_id, $eid]);
$eleve = $el->fetch();
if (!$eleve) repondreErreur("Élève introuvable.", 404);

// Infos de la période
$pe = $pdo->prepare("SELECT * FROM periodes_evaluation WHERE id = ? AND ecole_id = ?");
$pe->execute([$periode_id, $eid]);
$periode = $pe->fetch();
if (!$periode) repondreErreur("Période introuvable.", 404);

// Notes par matière
$stmt = $pdo->prepare("
    SELECT m.id AS matiere_id, m.nom AS matiere_nom, m.coefficient,
           n.id AS note_id, n.note, n.note_sur, n.commentaire,
           n.type_evaluation, n.date_evaluation
    FROM matieres m
    LEFT JOIN notes n ON n.matiere_id = m.id AND n.eleve_id = ? AND n.periode_id = ?
    WHERE m.ecole_id = ? AND (m.classe_id IS NULL OR m.classe_id = ?)
    ORDER BY m.nom
");
$stmt->execute([$eleve_id, $periode_id, $eid, $eleve['classe_id'] ?? 0]);
$matieres_notes = $stmt->fetchAll();

// Calculer la moyenne générale
$total_points = 0;
$total_coeffs = 0;
foreach ($matieres_notes as $mn) {
    if ($mn['note'] !== null) {
        $note_sur_20   = ($mn['note_sur'] > 0) ? ($mn['note'] / $mn['note_sur']) * 20 : 0;
        $total_points += $note_sur_20 * $mn['coefficient'];
        $total_coeffs += $mn['coefficient'];
    }
}
$moyenne_generale = ($total_coeffs > 0) ? round($total_points / $total_coeffs, 2) : null;

repondreJson([
    'eleve'            => $eleve,
    'periode'          => $periode,
    'notes'            => $matieres_notes,
    'moyenne_generale' => $moyenne_generale,
    'nb_matieres'      => count($matieres_notes),
    'nb_notes_saisies' => count(array_filter($matieres_notes, fn($m) => $m['note'] !== null)),
]);
