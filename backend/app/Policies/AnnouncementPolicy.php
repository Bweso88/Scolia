<?php

namespace App\Policies;

use App\Models\Announcement;
use App\Models\User;

class AnnouncementPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('announcement.view');
    }

    public function view(User $user, Announcement $announcement): bool
    {
        if ($user->tenant_id !== $announcement->tenant_id || ! $user->can('announcement.view')) {
            return false;
        }

        if ($user->can('announcement.publish')) {
            return true;
        }

        return $announcement->targets()->where(function ($query) use ($user) {
            $query->where('target_type', 'all')
                ->orWhere(fn ($q) => $q->where('target_type', 'user')->where('target_id', $user->id))
                ->orWhere(fn ($q) => $q->where('target_type', 'school_class')->whereIn(
                    'target_id',
                    $user->students()->pluck('school_class_id')
                ));
        })->exists();
    }

    public function create(User $user): bool
    {
        return $user->can('announcement.publish');
    }
}
