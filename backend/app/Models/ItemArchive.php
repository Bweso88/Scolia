<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

#[Fillable(['user_id', 'archivable_type', 'archivable_id'])]
class ItemArchive extends Model
{
    use BelongsToTenant;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function archivable(): MorphTo
    {
        return $this->morphTo();
    }
}
