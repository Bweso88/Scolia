<?php
/**
 * GET /api/ecole/stats
 */

$payload = exigerAuth();
exigerRole($payload, ['super_admin', 'school_admin', 'teacher']);
$pdo = getDB();
$eid = $payload['ecole_id'];

$nb_eleves  = $pdo->prepare("SELECT COUNT(*) FROM eleves WHERE ecole_id = ? AND actif = TRUE");
$nb_eleves->execute([$eid]);

$nb_parents = $pdo->prepare("SELECT COUNT(*) FROM utilisateurs WHERE ecole_id = ? AND role = 'parent' AND actif = TRUE");
$nb_parents->execute([$eid]);

$nb_classes = $pdo->prepare("SELECT COUNT(*) FROM classes WHERE ecole_id = ?");
$nb_classes->execute([$eid]);

$nb_messages = $pdo->prepare("SELECT COUNT(*) FROM messages_liaison WHERE ecole_id = ?");
$nb_messages->execute([$eid]);

$nb_dossiers_actifs = $pdo->prepare("SELECT COUNT(*) FROM dossiers_parents dp JOIN eleves e ON e.id = dp.eleve_id WHERE e.ecole_id = ? AND dp.actif = TRUE");
$nb_dossiers_actifs->execute([$eid]);

$frais_en_retard = $pdo->prepare("SELECT COUNT(*) FROM frais_scolarite fs JOIN eleves e ON e.id = fs.eleve_id WHERE e.ecole_id = ? AND fs.statut != 'paye'");
$frais_en_retard->execute([$eid]);

$dernieres_activites = $pdo->prepare("
    SELECT 'liaison' AS type, titre AS libelle, created_at
    FROM messages_liaison WHERE ecole_id = ?
    UNION ALL
    SELECT 'remarque', CONCAT(priorite, ' — ', LEFT(message, 50)), created_at
    FROM remarques WHERE ecole_id = ?
    UNION ALL
    SELECT 'evenement', titre, created_at
    FROM evenements WHERE ecole_id = ?
    ORDER BY created_at DESC LIMIT 5
");
$dernieres_activites->execute([$eid, $eid, $eid]);

repondreJson([
    'stats' => [
        'nb_eleves'          => (int) $nb_eleves->fetchColumn(),
        'nb_parents'         => (int) $nb_parents->fetchColumn(),
        'nb_classes'         => (int) $nb_classes->fetchColumn(),
        'nb_messages'        => (int) $nb_messages->fetchColumn(),
        'nb_dossiers_actifs' => (int) $nb_dossiers_actifs->fetchColumn(),
        'frais_en_retard'    => (int) $frais_en_retard->fetchColumn(),
    ],
    'dernieres_activites' => $dernieres_activites->fetchAll(),
]);
