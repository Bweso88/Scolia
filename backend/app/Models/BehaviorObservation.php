<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\BehaviorObservationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['student_id', 'author_user_id', 'category', 'title', 'description', 'occurred_at', 'visible_to_parent'])]
class BehaviorObservation extends Model
{
    /** @use HasFactory<BehaviorObservationFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
            'visible_to_parent' => 'boolean',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_user_id');
    }
}
