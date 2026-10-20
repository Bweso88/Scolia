<?php

namespace App\Http\Middleware;

use App\Support\Tenancy\TenantContext;
use Closure;
use Illuminate\Http\Request;
use Spatie\Permission\PermissionRegistrar;
use Symfony\Component\HttpFoundation\Response;

/**
 * Résout le tenant de la requête à partir de l'utilisateur authentifié
 * (jamais depuis l'URL ou un en-tête client, voir
 * docs/PRODUCT_ARCHITECTURE.md §9) et l'enregistre dans TenantContext,
 * consommé par App\Models\Scopes\TenantScope sur tous les modèles métier.
 *
 * Doit être placé après le middleware d'authentification sur toutes les
 * routes `api/v1/*` (hors routes plateforme, qui utilisent le guard
 * `platform` et ne passent jamais par ce middleware).
 */
class ResolveTenant
{
    public function __construct(private readonly TenantContext $tenantContext) {}

    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        abort_unless($user?->tenant_id, 403, 'Aucune école associée à ce compte.');

        $this->tenantContext->set($user->tenant);

        app(PermissionRegistrar::class)->setPermissionsTeamId($user->tenant_id);

        return $next($request);
    }
}
