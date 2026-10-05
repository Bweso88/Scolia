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
        return [
            'birth_date' => 'date',
            'activated_at' => 'datetime',
        ];
    }

    /**
     * Simule l'activation payante par enfant (docs/PRODUCT_ARCHITECTURE.md
     * §18 : la vraie facturation reste hors MVP) : un enfant non activé
     * n'est visible pour son parent que dans la liste, jamais en détail.
     */
    public function isActivated(): bool
    {
        return $this->activated_at !== null;
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

    /**
     * Même lien que guardians(), exposé comme HasMany sur le modèle pivot
     * lui-même plutôt que via la relation BelongsToMany — utilisé par le
     * RelationManager Filament pour que create() déclenche bien le
     * renseignement automatique de tenant_id (voir avertissement ci-dessus).
     */
    public function studentGuardians(): HasMany
    {
        return $this->hasMany(StudentGuardian::class);
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
