<?php

namespace App\Support\Talenda;

use App\Models\TenantSetting;
use App\Support\Tenancy\TenantContext;

final class Talenda
{
    /**
     * L'école courante est reliée à Talenda : ses élèves, classes,
     * matières, enseignants et parents se gèrent dans Talenda.
     */
    public static function connected(): bool
    {
        return app(TenantContext::class)->check()
            && (TenantSetting::query()->first()?->isConnectedToTalenda() ?? false);
    }
}
