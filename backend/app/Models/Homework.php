<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\HomeworkFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['lesson_id', 'school_class_id', 'subject_id', 'teacher_id', 'title', 'instructions', 'due_date', 'published_at'])]
class Homework extends Model
{
    /** @use HasFactory<HomeworkFactory> */
    use BelongsToTenant, HasFactory;

    // "homework" est invariable en anglais : Eloquent devinerait la table
    // "homework" au singulier, alors que la migration crée "homeworks".
    protected $table = 'homeworks';

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
            'published_at' => 'datetime',
        ];
    }

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class);
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(HomeworkAttachment::class);
    }

    public function statuses(): HasMany
    {
        return $this->hasMany(HomeworkStatus::class);
    }
}
