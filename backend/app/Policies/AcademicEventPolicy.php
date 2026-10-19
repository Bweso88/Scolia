<?php

namespace App\Policies;

use App\Models\AcademicEvent;
use App\Models\User;

/**
 * Événements du calendrier scolaire (vacances, examens, portes ouvertes...)
 * — propres à toute l'école, pas de ciblage par classe/élève contrairement
 * aux annonces (docs/PRODUCT_ARCHITECTURE.md — écran "Agenda").
 */
class AcademicEventPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('timetable.view');
    }

    public function view(User $user, AcademicEvent $event): bool
    {
        return $user->tenant_id === $event->tenant_id && $user->can('timetable.view');
    }

    public function create(User $user): bool
    {
        return $user->can('timetable.manage');
    }

    public function delete(User $user, AcademicEvent $event): bool
    {
        return $user->tenant_id === $event->tenant_id && $user->can('timetable.manage');
    }
}
