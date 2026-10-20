<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\ReportCardFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['student_id', 'grading_period_id', 'file_path', 'generated_at'])]
class ReportCard extends Model
{
    /** @use HasFactory<ReportCardFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['generated_at' => 'datetime'];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function gradingPeriod(): BelongsTo
    {
        return $this->belongsTo(GradingPeriod::class);
    }
}
