<?php

namespace App\Models\Scopes;

use App\Support\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

/**
 * Filtre automatiquement toute requête Eloquent sur le tenant actif.
 *
 * C'est le mécanisme central de l'isolation multi-tenant (voir
 * docs/PRODUCT_ARCHITECTURE.md §6) : aucun modèle utilisant
 * App\Models\Concerns\BelongsToTenant ne peut être interrogé en dehors de
 * son école sans passer explicitement par withoutGlobalScope(TenantScope::class),
 * ce qui est réservé au contexte Super Admin plateforme et doit rester
 * exceptionnel et revu en code review.
 */
class TenantScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        $context = app(TenantContext::class);

        if ($context->check()) {
            $builder->where($model->getTable().'.tenant_id', $context->id());
        }
    }
}
