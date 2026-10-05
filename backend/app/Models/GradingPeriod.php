<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\GradingPeriodFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['school_year_id', 'label'])]
class GradingPeriod extends Model
{
    /** @use HasFactory<GradingPeriodFactory> */
    use BelongsToTenant, HasFactory;

    public function schoolYear(): BelongsTo
    {
        return $this->belongsTo(SchoolYear::class);
    }

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class);
    }
}
