<?php

namespace App\Models;

use App\Models\Concerns\Archivable;
use App\Models\Concerns\BelongsToTenant;
use Database\Factories\BehaviorObservationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['student_id', 'author_user_id', 'category', 'title', 'description', 'occurred_at', 'visible_to_parent'])]
class BehaviorObservation extends Model
{
    /** @use HasFactory<BehaviorObservationFactory> */
    use Archivable, BelongsToTenant, HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
            'visible_to_parent' => 'boolean',
            'acknowledged_at' => 'datetime',
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

    public function acknowledgedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'acknowledged_by_user_id');
    }

    /**
     * Le représentant légal confirme avoir lu l'observation (accusé de
     * lecture, écran "Suivi" de l'espace parent).
     */
    public function acquitterPar(User $user): void
    {
        $this->acknowledged_at = now();
        $this->acknowledged_by_user_id = $user->id;
        $this->save();
    }
}
