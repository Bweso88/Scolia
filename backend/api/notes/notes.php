<?php
/**
 * GET/POST/PUT/DELETE /api/notes[/{id}]
 */

$payload = exigerAuth();
$pdo = getDB();
$eid = $payload['ecole_id'];
$id  = defined('ROUTE_ID') ? (int) ROUTE_ID : null;

if ($method === 'GET') {
    $page      = max(1, (int) ($_GET['page'] ?? 1));
    $eleve_id  = $_GET['eleve_id']  ?? null;
    $periode_id = $_GET['periode_id'] ?? null;
    $where  = "n.ecole_id = ?";
    $params = [$eid];

    if ($payload['role'] === 'parent') {
        $where .= " AND n.eleve_id IN (
            SELECT dp.eleve_id FROM dossiers_parents dp
            WHERE dp.parent_id = ? AND dp.actif = TRUE
            AND (dp.date_expiration IS NULL OR dp.date_expiration >= CURDATE())
        )";
        $params[] = $payload['user_id'];
    }

    if ($payload['role'] === 'teacher') {
        $cl = $pdo->prepare("SELECT id FROM classes WHERE enseignant_id = ? AND ecole_id = ?");
        $cl->execute([$payload['user_id'], $eid]);
        $ma_classe = $cl->fetch();
        if ($ma_classe) { $where .= " AND n.eleve_id IN (SELECT id FROM eleves WHERE classe_id = ?)"; $params[] = $ma_classe['id']; }
    }

    if ($eleve_id)  { $where .= " AND n.eleve_id = ?";  $params[] = $eleve_id; }
    if ($periode_id) { $where .= " AND n.periode_id = ?"; $params[] = $periode_id; }

    $result = paginer(
        $pdo,
        "SELECT COUNT(*) FROM notes n WHERE $where",
        "SELECT n.id, n.note, n.note_sur, n.commentaire, n.type_evaluation, n.date_evaluation, n.created_at,
                e.prenom AS eleve_prenom, e.nom AS eleve_nom,
                m.nom AS matiere_nom, m.coefficient,
                p.nom AS periode_nom,
                u.prenom AS saisie_prenom, u.nom AS saisie_nom
         FROM notes n
         JOIN eleves e ON e.id = n.eleve_id
         JOIN matieres m ON m.id = n.matiere_id
         JOIN periodes_evaluation p ON p.id = n.periode_id
         JOIN utilisateurs u ON u.id = n.saisie_par
         WHERE $where ORDER BY n.created_at DESC",
        $params, $page
    );
    repondreJson($result);
}

if ($method === 'POST') {
    exigerRole($payload, ['super_admin', 'school_admin', 'teacher']);
    $corps = corpsRequete();
    exigerChamps($corps, ['eleve_id', 'matiere_id', 'periode_id', 'note']);

    $note = (float) $corps['note'];
    $sur  = (float) ($corps['note_sur'] ?? 20);
    if ($note < 0 || $note > $sur) repondreErreur("Note invalide (doit être entre 0 et $sur).");

    $stmt = $pdo->prepare("
        INSERT INTO notes (ecole_id, eleve_id, matiere_id, periode_id, saisie_par, note, note_sur, commentaire, type_evaluation, date_evaluation)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $eid, $corps['eleve_id'], $corps['matiere_id'], $corps['periode_id'],
        $payload['user_id'], $note, $sur,
        $corps['commentaire'] ?? null,
        $corps['type_evaluation'] ?? 'controle',
        $corps['date_evaluation'] ?? date('Y-m-d'),
    ]);
    $note_id = (int) $pdo->lastInsertId();

    // Récupérer les infos pour la notification
    $el = $pdo->prepare("SELECT prenom, nom FROM eleves WHERE id = ?");
    $el->execute([$corps['eleve_id']]);
    $eleve = $el->fetch();

    $mat = $pdo->prepare("SELECT nom FROM matieres WHERE id = ?");
    $mat->execute([$corps['matiere_id']]);
    $matiere = $mat->fetch();

    $titre_n = "📊 Nouvelle note — {$matiere['nom']}";
    $corps_n = "{$eleve['prenom']} {$eleve['nom']} : {$note}/{$sur}";
    notifierParents($pdo, $eid, (int)$corps['eleve_id'], $titre_n, $corps_n, 'note', $note_id);

    repondreJson(['id' => $note_id, 'message' => 'Note enregistrée.'], 201);
}

if ($method === 'PUT' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin', 'teacher']);
    $corps  = corpsRequete();
    $champs = ['note', 'note_sur', 'commentaire', 'type_evaluation', 'date_evaluation'];
    $sets = []; $vals = [];
    foreach ($champs as $c) {
        if (array_key_exists($c, $corps)) { $sets[] = "$c = ?"; $vals[] = $corps[$c]; }
    }
    if (empty($sets)) repondreErreur("Aucun champ à modifier.");
    $vals[] = $id; $vals[] = $eid;
    $pdo->prepare("UPDATE notes SET " . implode(', ', $sets) . " WHERE id = ? AND ecole_id = ?")->execute($vals);
    repondreSucces(null, 'Note mise à jour.');
}

if ($method === 'DELETE' && $id) {
    exigerRole($payload, ['super_admin', 'school_admin']);
    $pdo->prepare("DELETE FROM notes WHERE id = ? AND ecole_id = ?")->execute([$id, $eid]);
    repondreSucces(null, 'Note supprimée.');
}
