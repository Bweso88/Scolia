<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SchoolClassFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['school_year_id', 'name', 'level', 'homeroom_teacher_id'])]
class SchoolClass extends Model
{
    /** @use HasFactory<SchoolClassFactory> */
    use BelongsToTenant, HasFactory;

    protected $table = 'school_classes';

    public function schoolYear(): BelongsTo
    {
        return $this->belongsTo(SchoolYear::class);
    }

    public function homeroomTeacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class, 'homeroom_teacher_id');
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class);
    }

    public function timetableSlots(): HasMany
    {
        return $this->hasMany(TimetableSlot::class);
    }

    public function homeworks(): HasMany
    {
        return $this->hasMany(Homework::class);
    }
}
