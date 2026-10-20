<?php
/**
 * SCOLIA — Configuration base de données (PostgreSQL)
 */

define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'scolia');
define('DB_USER', getenv('DB_USER') ?: 'postgres');
define('DB_PASS', getenv('DB_PASS') ?: '');
define('DB_PORT', getenv('DB_PORT') ?: '5432');

/**
 * PDO étendu : lastInsertId() sans argument utilise lastval() (équivalent
 * de LAST_INSERT_ID() MySQL) pour récupérer le dernier id généré par SERIAL.
 */
class ScoliaPDO extends PDO {
    public function lastInsertId(?string $name = null): string|false {
        if ($name === null) {
            $stmt = parent::query('SELECT lastval()');
            return (string) $stmt->fetchColumn();
        }
        return parent::lastInsertId($name);
    }
}

function getDB(): ScoliaPDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', DB_HOST, DB_PORT, DB_NAME);
        $pdo = new ScoliaPDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }
    return $pdo;
}
