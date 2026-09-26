<?php

namespace App\Policies;

use App\Models\BehaviorObservation;
use App\Models\User;

class BehaviorObservationPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('behavior.view');
    }

    public function view(User $user, BehaviorObservation $observation): bool
    {
        if ($user->tenant_id !== $observation->tenant_id || ! $user->can('behavior.view')) {
            return false;
        }

        if ($user->can('student.manage') || $user->hasRole('teacher') || $user->hasRole('surveillant')) {
            return true;
        }

        // Un parent ne voit que les observations visibles concernant ses propres enfants.
        return $observation->visible_to_parent
            && $observation->student->guardians()->whereKey($user->id)->exists();
    }

    public function create(User $user): bool
    {
        return $user->can('behavior.create');
    }

    /**
     * Seuls l'auteur de l'observation ou l'administration peuvent la
     * supprimer (correction d'une erreur de saisie).
     */
    public function delete(User $user, BehaviorObservation $observation): bool
    {
        if ($user->tenant_id !== $observation->tenant_id) {
            return false;
        }

        return $user->hasRole(['school_admin', 'direction']) || $observation->author_user_id === $user->id;
    }
}
