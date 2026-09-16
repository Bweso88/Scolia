<?php
/**
 * SCOLIA — Fonctions de réponse HTTP standardisées
 */

function repondreJson(mixed $data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function repondreErreur(string $message, int $code = 400): void {
    repondreJson(['erreur' => $message], $code);
}

function repondreSucces(mixed $data = null, string $message = 'Succès'): void {
    $reponse = ['succes' => true, 'message' => $message];
    if ($data !== null) $reponse['data'] = $data;
    repondreJson($reponse);
}

function corpsRequete(): array {
    $corps = json_decode(file_get_contents('php://input'), true);
    return is_array($corps) ? $corps : [];
}

function exigerChamps(array $corps, array $champs): void {
    foreach ($champs as $champ) {
        if (!isset($corps[$champ]) || $corps[$champ] === '') {
            repondreErreur("Champ requis manquant : $champ");
        }
    }
}

function paginer(PDO $pdo, string $sql_count, string $sql_data, array $params, int $page, int $par_page = 20): array {
    $stmt = $pdo->prepare($sql_count);
    $stmt->execute($params);
    $total = (int) $stmt->fetchColumn();

    $offset = ($page - 1) * $par_page;
    $stmt2  = $pdo->prepare("$sql_data LIMIT $par_page OFFSET $offset");
    $stmt2->execute($params);
    $items = $stmt2->fetchAll();

    return [
        'items'      => $items,
        'total'      => $total,
        'page'       => $page,
        'par_page'   => $par_page,
        'pages'      => (int) ceil($total / $par_page),
    ];
}
