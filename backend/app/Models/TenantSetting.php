<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\TenantSettingFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'display_name', 'logo_path', 'cover_image_path', 'primary_color',
    'secondary_color', 'phone', 'email', 'address', 'website', 'current_school_year_id',
    'messaging_cutoff_time',
])]
class TenantSetting extends Model
{
    /** @use HasFactory<TenantSettingFactory> */
    use BelongsToTenant, HasFactory;

    public function currentSchoolYear(): BelongsTo
    {
        return $this->belongsTo(SchoolYear::class, 'current_school_year_id');
    }

    /**
     * Un parent ne peut plus initier de nouveau message passé cette heure
     * (docs/PRODUCT_ARCHITECTURE.md §7) ; le personnel n'y est jamais
     * soumis. Nulle = pas de restriction pour ce tenant.
     */
    public function isPastMessagingCutoff(): bool
    {
        if ($this->messaging_cutoff_time === null) {
            return false;
        }

        return now()->format('H:i:s') > $this->messaging_cutoff_time;
    }
}
