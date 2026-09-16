<?php

namespace App\Models;

use App\Services\Tenancy\TenantProvisioner;
use Database\Factories\TenantFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['name', 'slug', 'status', 'school_year_start_month', 'timezone', 'locale'])]
class Tenant extends Model
{
    /** @use HasFactory<TenantFactory> */
    use HasFactory;

    /**
     * Provisionne automatiquement les rôles de l'école à sa création
     * (voir App\Services\Tenancy\TenantProvisioner) : ajouter une école
     * ne demande jamais de modification de code.
     */
    protected static function booted(): void
    {
        static::created(function (Tenant $tenant): void {
            app(TenantProvisioner::class)->provision($tenant);
        });
    }

    public function settings(): HasOne
    {
        return $this->hasOne(TenantSetting::class);
    }

    public function subscription(): HasOne
    {
        return $this->hasOne(Subscription::class)->latestOfMany();
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class);
    }

    public function schoolClasses(): HasMany
    {
        return $this->hasMany(SchoolClass::class);
    }

    public function subscriptionModules(): HasMany
    {
        return $this->hasMany(SubscriptionModule::class);
    }

    /**
     * Un module est actif par défaut tant que l'école ne l'a pas
     * explicitement désactivé (docs/PRODUCT_ARCHITECTURE.md §4 et §18) —
     * seule une ligne subscription_modules avec is_enabled=false le coupe.
     */
    public function isModuleEnabled(string $key): bool
    {
        return $this->subscriptionModules()->where('module_key', $key)->value('is_enabled') ?? true;
    }
}
