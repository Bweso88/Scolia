<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\StudentGuardianFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['student_id', 'user_id', 'relationship_type', 'is_primary_contact'])]
class StudentGuardian extends Model
{
    /** @use HasFactory<StudentGuardianFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['is_primary_contact' => 'boolean'];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function guardianUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
