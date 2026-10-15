<?php

namespace App\Policies;

use App\Models\Grade;
use App\Models\User;

class GradePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('grade.view');
    }

    public function view(User $user, Grade $grade): bool
    {
        if ($user->tenant_id !== $grade->tenant_id || ! $user->can('grade.view')) {
            return false;
        }

        return $user->can('grade.manage') || $grade->student->guardians()->whereKey($user->id)->exists();
    }

    public function create(User $user): bool
    {
        return $user->can('grade.manage');
    }

    public function update(User $user, Grade $grade): bool
    {
        return $user->tenant_id === $grade->tenant_id && $user->can('grade.manage');
    }
}
