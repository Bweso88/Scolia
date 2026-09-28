<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\AcademicEventFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'description', 'start_date', 'end_date', 'category'])]
class AcademicEvent extends Model
{
    /** @use HasFactory<AcademicEventFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
        ];
    }
}
