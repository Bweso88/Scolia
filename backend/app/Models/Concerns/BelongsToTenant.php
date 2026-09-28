<?php

namespace App\Models\Concerns;

use App\Models\Scopes\TenantScope;
use App\Models\Tenant;
use App\Support\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * À utiliser sur tout modèle métier portant une colonne tenant_id.
 * Applique le TenantScope global et renseigne tenant_id automatiquement
 * à la création à partir du contexte de la requête courante.
 *
 * Piège à connaître : ceci ne se déclenche que sur un create() Eloquent.
 * Pour une table pivot qui porte tenant_id (ex. student_guardians,
 * teacher_assignments, conversation_participants), créer la ligne via son
 * propre modèle Eloquent — jamais via attach()/sync()/detach() sur une
 * relation BelongsToMany, qui font un insert SQL direct sans déclencher
 * cet événement et laissent tenant_id à NULL.
 */
trait BelongsToTenant
{
    public static function bootBelongsToTenant(): void
    {
        static::addGlobalScope(new TenantScope);

        static::creating(function ($model): void {
            if (empty($model->tenant_id)) {
                $context = app(TenantContext::class);

                if ($context->check()) {
                    $model->tenant_id = $context->id();
                }
            }
        });
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
