<?php

namespace App\Policies;

use App\Models\SchoolClass;
use App\Models\User;

class SchoolClassPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('student.view');
    }

    public function view(User $user, SchoolClass $schoolClass): bool
    {
        return $user->tenant_id === $schoolClass->tenant_id && $user->can('student.view');
    }

    public function create(User $user): bool
    {
        return $user->can('schoolclass.manage');
    }

    public function update(User $user, SchoolClass $schoolClass): bool
    {
        return $user->tenant_id === $schoolClass->tenant_id && $user->can('schoolclass.manage');
    }

    public function delete(User $user, SchoolClass $schoolClass): bool
    {
        return $user->tenant_id === $schoolClass->tenant_id && $user->can('schoolclass.manage');
    }
}
