<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Models\Concerns\BelongsToTenant;
use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\PermissionRegistrar;
use Spatie\Permission\Traits\HasRoles;

#[Fillable(['name', 'email', 'phone', 'password', 'locale', 'is_active'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable implements FilamentUser
{
    /** @use HasFactory<UserFactory> */
    use BelongsToTenant, HasApiTokens, HasFactory, HasRoles, Notifiable;

    /**
     * Le panel /admin (Filament) est réservé à la direction de l'école ;
     * les rôles spatie sont scopés par tenant (teams), donc il faut
     * positionner le team_id du registrar avant de vérifier le rôle — voir
     * App\Http\Controllers\Api\V1\Auth\AuthController::respondWithToken
     * pour la même nécessité côté API.
     */
    public function canAccessPanel(Panel $panel): bool
    {
        app(PermissionRegistrar::class)->setPermissionsTeamId($this->tenant_id);

        return $this->is_active && $this->hasAnyRole(['school_admin', 'direction']);
    }

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function parentIdentity(): BelongsTo
    {
        return $this->belongsTo(ParentIdentity::class);
    }

    public function teacher(): HasOne
    {
        return $this->hasOne(Teacher::class);
    }

    public function students(): BelongsToMany
    {
        return $this->belongsToMany(Student::class, 'student_guardians')
            ->withPivot(['relationship_type', 'is_primary_contact'])
            ->withTimestamps();
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function notificationPreferences(): HasMany
    {
        return $this->hasMany(NotificationPreference::class);
    }

    /**
     * Un utilisateur n'ayant jamais réglé ses préférences reçoit tout par
     * défaut (docs/PRODUCT_ARCHITECTURE.md §16) : seule une préférence
     * explicite is_enabled=false coupe une catégorie/canal.
     */
    public function wantsNotification(string $category, string $channel): bool
    {
        return $this->notificationPreferences()
            ->where('category', $category)
            ->where('channel', $channel)
            ->value('is_enabled') ?? true;
    }
}
