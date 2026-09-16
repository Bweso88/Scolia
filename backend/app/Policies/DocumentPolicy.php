<?php

namespace App\Policies;

use App\Models\Document;
use App\Models\User;

class DocumentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('document.view');
    }

    public function view(User $user, Document $document): bool
    {
        if ($user->tenant_id !== $document->tenant_id || ! $user->can('document.view')) {
            return false;
        }

        if ($user->can('document.manage')) {
            return true;
        }

        return match ($document->visible_to) {
            'all' => true,
            'user' => $document->target_id === $user->id,
            'student' => $user->students()->whereKey($document->target_id)->exists(),
            'school_class' => $user->students()->where('school_class_id', $document->target_id)->exists(),
            default => false,
        };
    }

    public function create(User $user): bool
    {
        return $user->can('document.manage');
    }

    public function delete(User $user, Document $document): bool
    {
        return $user->tenant_id === $document->tenant_id && $user->can('document.manage');
    }
}
