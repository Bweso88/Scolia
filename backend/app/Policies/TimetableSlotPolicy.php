<?php

namespace App\Policies;

use App\Models\TimetableSlot;
use App\Models\User;

class TimetableSlotPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('timetable.view');
    }

    public function view(User $user, TimetableSlot $slot): bool
    {
        return $user->tenant_id === $slot->tenant_id && $user->can('timetable.view');
    }

    public function create(User $user): bool
    {
        return $user->can('timetable.manage');
    }

    public function update(User $user, TimetableSlot $slot): bool
    {
        return $user->tenant_id === $slot->tenant_id && $user->can('timetable.manage');
    }

    public function delete(User $user, TimetableSlot $slot): bool
    {
        return $user->tenant_id === $slot->tenant_id && $user->can('timetable.manage');
    }
}
