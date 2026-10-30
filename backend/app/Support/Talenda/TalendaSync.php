<?php

namespace App\Support\Talenda;

use Closure;

/**
 * Indique qu'une synchronisation depuis Talenda est en cours : seule elle
 * peut modifier les fiches gérées par Talenda (voir ManagedByTalenda).
 */
final class TalendaSync
{
    private static int $depth = 0;

    public static function isRunning(): bool
    {
        return self::$depth > 0;
    }

    /**
     * @template T
     *
     * @param  Closure(): T  $callback
     * @return T
     */
    public static function run(Closure $callback): mixed
    {
        self::$depth++;

        try {
            return $callback();
        } finally {
            self::$depth--;
        }
    }
}
