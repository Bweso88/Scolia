<?php

namespace App\Models;

use Database\Factories\ParentIdentityFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Relie les comptes `users` d'un même parent lorsqu'il a des enfants
 * dans plusieurs écoles (voir docs/PRODUCT_ARCHITECTURE.md §6).
 * Ne porte volontairement pas de tenant_id : c'est l'identité qui
 * traverse les tenants, jamais les données scolaires elles-mêmes.
 */
#[Fillable(['full_name', 'canonical_email', 'canonical_phone'])]
class ParentIdentity extends Model
{
    /** @use HasFactory<ParentIdentityFactory> */
    use HasFactory;

    public function accounts(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
