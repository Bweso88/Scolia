<?php

namespace App\Support\Talenda;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

/**
 * Tentative de créer, modifier ou supprimer dans Scolia une fiche dont Talenda
 * est la référence.
 */
class ManagedByTalendaException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Géré dans Talenda : faites ce changement dans Talenda, il arrivera ici à la prochaine synchronisation.');
    }

    public function render(Request $request): ?JsonResponse
    {
        return $request->expectsJson() || $request->is('api/*')
            ? response()->json(['message' => $this->getMessage()], 409)
            : null;
    }
}
