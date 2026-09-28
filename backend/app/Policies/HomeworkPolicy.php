<?php

namespace App\Policies;

use App\Models\Homework;
use App\Models\User;

class HomeworkPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('homework.view');
    }

    public function view(User $user, Homework $homework): bool
    {
        return $user->tenant_id === $homework->tenant_id && $user->can('homework.view');
    }

    public function create(User $user): bool
    {
        return $user->can('homework.create');
    }

    public function update(User $user, Homework $homework): bool
    {
        if ($user->tenant_id !== $homework->tenant_id || ! $user->can('homework.update')) {
            return false;
        }

        // Un enseignant ne modifie que ses propres devoirs ; direction/admin
        // (permission accordée sans restriction de propriétaire) peuvent tout.
        return $user->can('student.manage') || $homework->teacher?->user_id === $user->id;
    }

    public function delete(User $user, Homework $homework): bool
    {
        return $user->tenant_id === $homework->tenant_id && $user->can('homework.delete');
    }
}
