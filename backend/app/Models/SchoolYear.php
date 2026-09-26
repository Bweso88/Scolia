<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SchoolYearFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['label', 'start_date', 'end_date', 'is_current'])]
class SchoolYear extends Model
{
    /** @use HasFactory<SchoolYearFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'is_current' => 'boolean',
        ];
    }

    public function schoolClasses(): HasMany
    {
        return $this->hasMany(SchoolClass::class);
    }
}
