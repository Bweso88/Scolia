<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\TimetableSlotFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['school_class_id', 'subject_id', 'teacher_id', 'day_of_week', 'start_time', 'end_time', 'room'])]
class TimetableSlot extends Model
{
    /** @use HasFactory<TimetableSlotFactory> */
    use BelongsToTenant, HasFactory;

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
}
