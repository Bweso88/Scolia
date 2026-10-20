<?php

namespace App\Policies;

use App\Models\AttendanceRecord;
use App\Models\User;

class AttendanceRecordPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('attendance.view');
    }

    public function view(User $user, AttendanceRecord $record): bool
    {
        if ($user->tenant_id !== $record->tenant_id || ! $user->can('attendance.view')) {
            return false;
        }

        if ($user->can('student.manage') || $user->hasRole(['teacher', 'surveillant'])) {
            return true;
        }

        return $record->student->guardians()->whereKey($user->id)->exists();
    }

    public function create(User $user): bool
    {
        return $user->can('attendance.create');
    }

    /**
     * Seul un parent de l'élève concerné peut justifier une absence, et
     * uniquement s'il n'existe pas déjà de justificatif.
     */
    public function justify(User $user, AttendanceRecord $record): bool
    {
        return $user->tenant_id === $record->tenant_id
            && $user->can('attendance.justify')
            && $record->student->guardians()->whereKey($user->id)->exists()
            && ! $record->justification()->exists();
    }

    public function review(User $user, AttendanceRecord $record): bool
    {
        return $user->tenant_id === $record->tenant_id && $user->can('attendance.review');
    }
}
