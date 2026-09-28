<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\HomeworkAttachmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['homework_id', 'file_path', 'file_name', 'mime_type', 'size_bytes'])]
class HomeworkAttachment extends Model
{
    /** @use HasFactory<HomeworkAttachmentFactory> */
    use BelongsToTenant, HasFactory;

    public function homework(): BelongsTo
    {
        return $this->belongsTo(Homework::class);
    }
}
