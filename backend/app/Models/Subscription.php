<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SubscriptionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['plan_id', 'status', 'current_period_start', 'current_period_end', 'students_count_cache'])]
class Subscription extends Model
{
    /** @use HasFactory<SubscriptionFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return [
            'current_period_start' => 'date',
            'current_period_end' => 'date',
        ];
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }
}
