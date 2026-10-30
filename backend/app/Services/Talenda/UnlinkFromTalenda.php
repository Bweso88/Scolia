<?php

namespace App\Services\Talenda;

use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\Tenant;
use App\Models\TenantSetting;
use App\Models\User;
use App\Support\Talenda\TalendaSync;
use App\Support\Tenancy\TenantContext;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Délie une école de Talenda (docs/JONCTION_TALENDA.md) : Scolia redevient
 * autonome pour elle. Toutes les fiches sont conservées et redeviennent
 * modifiables dans Scolia.
 *
 * Les comptes qui se sont déjà connectés à Scolia gardent leur mot de passe
 * (celui de Talenda, dont Scolia garde une copie hachée). Les autres n'en
 * ont aucun : un mot de passe provisoire leur est attribué, à leur
 * transmettre.
 */
class UnlinkFromTalenda
{
    public function __construct(private readonly TenantContext $tenantContext) {}

    /**
     * @return list<array{name: string, phone: ?string, email: ?string, password: string}>
     */
    public function handle(Tenant $tenant): array
    {
        $previousTenant = $this->tenantContext->get();
        $this->tenantContext->set($tenant);

        try {
            return TalendaSync::run(fn (): array => DB::transaction(function (): array {
                $temporaryPasswords = [];

                $users = User::query()
                    ->where(fn ($query) => $query->whereNotNull('talenda_account_uuid')->orWhereNotNull('talenda_guardian_uuid'))
                    ->orderBy('name')
                    ->get();

                foreach ($users as $user) {
                    $attributes = ['talenda_account_uuid' => null, 'talenda_guardian_uuid' => null];

                    if ($user->last_login_at === null && $user->is_active) {
                        $attributes['password'] = $password = Str::password(10, symbols: false);
                        $temporaryPasswords[] = ['name' => $user->name, 'phone' => $user->phone, 'email' => $user->email, 'password' => $password];
                    }

                    $user->forceFill($attributes)->save();
                }

                foreach ([SchoolYear::class, Subject::class, SchoolClass::class, Teacher::class, Student::class] as $model) {
                    $model::query()->whereNotNull('talenda_uuid')->update(['talenda_uuid' => null]);
                }

                TenantSetting::query()->sole()->forceFill([
                    'talenda_url' => null,
                    'talenda_token' => null,
                    'talenda_synced_at' => null,
                    'talenda_sync_error' => null,
                ])->save();

                return $temporaryPasswords;
            }));
        } finally {
            $this->tenantContext->set($previousTenant);
        }
    }
}
