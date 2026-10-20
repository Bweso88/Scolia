<?php

namespace App\Policies;

use App\Models\Student;
use App\Models\User;

/**
 * Défense en profondeur : le TenantScope global filtre déjà les requêtes,
 * mais chaque policy revérifie explicitement l'appartenance au même
 * tenant (docs/PRODUCT_ARCHITECTURE.md §6, point 5) en plus des
 * permissions spatie.
 */
class StudentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('student.view');
    }

    public function view(User $user, Student $student): bool
    {
        if ($user->tenant_id !== $student->tenant_id) {
            return false;
        }

        if ($user->can('student.manage') || $user->hasRole(['teacher', 'surveillant'])) {
            return $user->can('student.view');
        }

        // Un parent ne voit que ses propres enfants (affiné aux élèves de
        // ses classes précises pour l'enseignant en V2, via
        // teacher_assignments).
        return $user->can('student.view')
            && $student->guardians()->whereKey($user->id)->exists();
    }

    public function create(User $user): bool
    {
        return $user->can('student.manage');
    }

    public function update(User $user, Student $student): bool
    {
        return $user->tenant_id === $student->tenant_id && $user->can('student.manage');
    }

    public function delete(User $user, Student $student): bool
    {
        return $user->tenant_id === $student->tenant_id && $user->can('student.manage');
    }
}
