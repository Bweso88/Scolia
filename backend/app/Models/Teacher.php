<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\TeacherFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['user_id', 'employee_number'])]
class Teacher extends Model
{
    /** @use HasFactory<TeacherFactory> */
    use BelongsToTenant, HasFactory;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(TeacherAssignment::class);
    }

    public function schoolClasses(): BelongsToMany
    {
        return $this->belongsToMany(SchoolClass::class, 'teacher_assignments')
            ->withPivot('subject_id')
            ->withTimestamps();
    }

    public function messagingPermission(): HasOne
    {
        return $this->hasOne(MessagingPermission::class);
    }
}
