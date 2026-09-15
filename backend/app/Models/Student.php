<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\StudentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['school_class_id', 'first_name', 'last_name', 'birth_date', 'gender', 'enrollment_number', 'status'])]
class Student extends Model
{
    /** @use HasFactory<StudentFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['birth_date' => 'date'];
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class);
    }

    /**
     * Lecture seule : student_guardians porte tenant_id, renseigné par le
     * modèle StudentGuardian (BelongsToTenant). Pour créer un lien,
     * utiliser StudentGuardian::create(...), jamais attach()/sync(), qui
     * feraient un insert direct sans déclencher cet événement.
     */
    public function guardians(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'student_guardians')
            ->withPivot(['relationship_type', 'is_primary_contact'])
            ->withTimestamps();
    }

    public function homeworkStatuses(): HasMany
    {
        return $this->hasMany(HomeworkStatus::class);
    }

    public function behaviorObservations(): HasMany
    {
        return $this->hasMany(BehaviorObservation::class);
    }

    public function attendanceRecords(): HasMany
    {
        return $this->hasMany(AttendanceRecord::class);
    }

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class);
    }
}
