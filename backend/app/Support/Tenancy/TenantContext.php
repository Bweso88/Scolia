<?php

namespace App\Support\Tenancy;

use App\Models\Tenant;

/**
 * Tenant actif de la requête courante. Renseigné uniquement par
 * App\Http\Middleware\ResolveTenant — jamais déduit d'une entrée
 * utilisateur (URL, en-tête) pour éviter qu'un client choisisse son tenant.
 *
 * Ce singleton est vidé à chaque nouvelle requête PHP-FPM classique ; en cas
 * de bascule vers Octane, il faudra le réinitialiser sur RequestTerminated.
 */
class TenantContext
{
    private ?Tenant $tenant = null;

    public function set(?Tenant $tenant): void
    {
        $this->tenant = $tenant;
    }

    public function get(): ?Tenant
    {
        return $this->tenant;
    }

    public function id(): ?int
    {
        return $this->tenant?->id;
    }

    public function check(): bool
    {
        return $this->tenant !== null;
    }
}
