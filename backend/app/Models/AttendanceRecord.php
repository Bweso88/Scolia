<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\AttendanceRecordFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['student_id', 'type', 'date', 'start_time', 'end_time', 'reason', 'recorded_by_user_id'])]
class AttendanceRecord extends Model
{
    /** @use HasFactory<AttendanceRecordFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['date' => 'date'];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by_user_id');
    }

    public function justification(): HasOne
    {
        return $this->hasOne(AttendanceJustification::class);
    }
}
