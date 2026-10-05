<?php

namespace App\Services\Tenancy;

use App\Models\Tenant;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

/**
 * Provisionne automatiquement les rôles d'une nouvelle école, pour tenir la
 * promesse « ajouter une école = une ligne dans tenants, aucune
 * modification de code » (docs/PRODUCT_ARCHITECTURE.md §6 et §15).
 *
 * Les permissions sont globales (partagées entre tenants, spatie ne les
 * teame pas) ; seuls les rôles sont créés par tenant (team = tenant_id).
 */
class TenantProvisioner
{
    public function provision(Tenant $tenant): void
    {
        $this->ensurePermissionsExist();

        $registrar = app(PermissionRegistrar::class);
        $previousTeamId = $registrar->getPermissionsTeamId();

        try {
            $registrar->setPermissionsTeamId($tenant->id);

            foreach (config('scolia.roles') as $roleName => $permissions) {
                $role = Role::firstOrCreate([
                    'name' => $roleName,
                    'guard_name' => 'web',
                    'tenant_id' => $tenant->id,
                ]);

                if ($permissions === '*') {
                    $role->syncPermissions(Permission::all());
                } else {
                    $role->syncPermissions($permissions);
                }
            }
        } finally {
            $registrar->setPermissionsTeamId($previousTeamId);
        }
    }

    private function ensurePermissionsExist(): void
    {
        foreach (config('scolia.permissions') as $permission) {
            Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'web']);
        }
    }
}
