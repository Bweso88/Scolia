<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\AttendanceJustificationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['attendance_record_id', 'submitted_by_user_id', 'explanation', 'attachment_path', 'status', 'reviewed_by_user_id', 'reviewed_at'])]
class AttendanceJustification extends Model
{
    /** @use HasFactory<AttendanceJustificationFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['reviewed_at' => 'datetime'];
    }

    public function attendanceRecord(): BelongsTo
    {
        return $this->belongsTo(AttendanceRecord::class);
    }

    public function submittedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by_user_id');
    }

    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by_user_id');
    }
}
