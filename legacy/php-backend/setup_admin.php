<?php
/**
 * SCOLIA — Script de configuration initiale
 * Crée le premier super_admin et la première école
 *
 * Usage : php setup_admin.php (en ligne de commande)
 * ou accéder via navigateur UNE SEULE FOIS puis supprimer ce fichier
 */

require_once __DIR__ . '/config/database.php';

// ─── Configuration initiale — modifier avant exécution ───────────────────────
$config = [
    'ecole' => [
        'nom'            => 'École Primaire Exemple',
        'slug'           => 'ecole-exemple',
        'ville'          => 'Brazzaville',
        'telephone'      => '+242060000000',
        'email'          => 'admin@ecole-exemple.cg',
        'annee_scolaire' => '2025-2026',
        'date_debut_scolarite' => '2025-09-01',
        'date_fin_scolarite'   => '2026-06-30',
        'plan'           => 'pro',
        'date_debut_abonnement' => date('Y-m-d'),
        'date_fin_abonnement'   => '2026-08-31',
    ],
    'admin' => [
        'telephone' => '+242060000001',
        'prenom'    => 'Super',
        'nom'       => 'Admin',
        'role'      => 'super_admin',
    ],
];
// ─────────────────────────────────────────────────────────────────────────────

try {
    $pdo = getDB();

    // Vérifier si déjà initialisé
    $check = $pdo->query("SELECT COUNT(*) FROM utilisateurs")->fetchColumn();
    if ($check > 0) {
        echo json_encode(['erreur' => 'La base de données est déjà initialisée.']);
        exit(1);
    }

    $pdo->beginTransaction();

    // Créer l'école
    $stmt = $pdo->prepare("
        INSERT INTO ecoles (nom, slug, ville, telephone, email, annee_scolaire,
            date_debut_scolarite, date_fin_scolarite, plan,
            date_debut_abonnement, date_fin_abonnement, actif)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
    ");
    $stmt->execute([
        $config['ecole']['nom'],
        $config['ecole']['slug'],
        $config['ecole']['ville'],
        $config['ecole']['telephone'],
        $config['ecole']['email'],
        $config['ecole']['annee_scolaire'],
        $config['ecole']['date_debut_scolarite'],
        $config['ecole']['date_fin_scolarite'],
        $config['ecole']['plan'],
        $config['ecole']['date_debut_abonnement'],
        $config['ecole']['date_fin_abonnement'],
    ]);
    $ecole_id = $pdo->lastInsertId();

    // Créer le super admin
    $stmt = $pdo->prepare("
        INSERT INTO utilisateurs (ecole_id, telephone, prenom, nom, role, actif)
        VALUES (?, ?, ?, ?, ?, TRUE)
    ");
    $stmt->execute([
        $ecole_id,
        $config['admin']['telephone'],
        $config['admin']['prenom'],
        $config['admin']['nom'],
        $config['admin']['role'],
    ]);
    $admin_id = $pdo->lastInsertId();

    $pdo->commit();

    echo json_encode([
        'succes'     => true,
        'message'    => 'Configuration initiale terminée.',
        'ecole_id'   => $ecole_id,
        'admin_id'   => $admin_id,
        'telephone'  => $config['admin']['telephone'],
        'instruction' => 'Connectez-vous avec ce numéro via OTP. Supprimez ce fichier après utilisation.',
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo json_encode(['erreur' => $e->getMessage()]);
    exit(1);
}
