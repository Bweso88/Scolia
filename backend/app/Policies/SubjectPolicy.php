<?php

namespace App\Policies;

use App\Models\Subject;
use App\Models\User;

class SubjectPolicy
{
    public function create(User $user): bool
    {
        return $user->can('schoolclass.manage');
    }

    public function update(User $user, Subject $subject): bool
    {
        return $user->tenant_id === $subject->tenant_id && $user->can('schoolclass.manage');
    }

    public function delete(User $user, Subject $subject): bool
    {
        return $user->tenant_id === $subject->tenant_id && $user->can('schoolclass.manage');
    }
}
