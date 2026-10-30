<?php

namespace App\Console\Commands;

use App\Models\Tenant;
use App\Models\TenantSetting;
use App\Services\Talenda\SyncFromTalenda;
use App\Support\Talenda\TalendaUnavailable;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Synchronise les écoles reliées à Talenda (planifié toutes les 15 minutes,
 * voir routes/console.php).
 */
#[Signature('scolia:talenda-sync {tenant? : Slug d\'une seule école}')]
#[Description('Met à jour élèves, classes, matières, enseignants et parents depuis Talenda')]
class SyncTalenda extends Command
{
    public function handle(SyncFromTalenda $sync): int
    {
        $tenants = Tenant::query()
            ->whereIn('status', ['trial', 'active'])
            ->when($this->argument('tenant'), fn ($query, string $slug) => $query->where('slug', $slug))
            ->whereIn('id', TenantSetting::query()->whereNotNull('talenda_url')->whereNotNull('talenda_token')->select('tenant_id'))
            ->get();

        $failed = false;

        foreach ($tenants as $tenant) {
            try {
                $counts = $sync->handle($tenant);
                $this->info("{$tenant->name} : {$counts['students']} élèves, {$counts['guardians']} parents, {$counts['teachers']} enseignants, {$counts['classes']} classes.");
            } catch (TalendaUnavailable $exception) {
                $failed = true;
                $this->error("{$tenant->name} : {$exception->getMessage()}");
            }
        }

        return $failed ? self::FAILURE : self::SUCCESS;
    }
}
