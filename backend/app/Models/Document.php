<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\DocumentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'category', 'file_path', 'visible_to', 'target_id', 'uploaded_by_user_id'])]
class Document extends Model
{
    /** @use HasFactory<DocumentFactory> */
    use BelongsToTenant, HasFactory;

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }
}
