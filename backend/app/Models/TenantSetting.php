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
])]
class TenantSetting extends Model
{
    /** @use HasFactory<TenantSettingFactory> */
    use BelongsToTenant, HasFactory;

    public function currentSchoolYear(): BelongsTo
    {
        return $this->belongsTo(SchoolYear::class, 'current_school_year_id');
    }
}
