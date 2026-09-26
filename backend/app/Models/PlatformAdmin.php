<?php

namespace App\Models;

use Database\Factories\PlatformAdminFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;

/**
 * Super Admin de la plateforme, guard `platform` séparé du guard école.
 * Ne porte pas de tenant_id : voit toutes les écoles par construction,
 * jamais au travers du TenantScope (voir §17, mode support journalisé).
 */
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class PlatformAdmin extends Authenticatable
{
    /** @use HasFactory<PlatformAdminFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return ['password' => 'hashed'];
    }
}
