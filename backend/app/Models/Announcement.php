<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\AnnouncementFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['author_user_id', 'title', 'body', 'category', 'published_at'])]
class Announcement extends Model
{
    /** @use HasFactory<AnnouncementFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['published_at' => 'datetime'];
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_user_id');
    }

    public function targets(): HasMany
    {
        return $this->hasMany(AnnouncementTarget::class);
    }
}
