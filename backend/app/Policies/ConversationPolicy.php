<?php

namespace App\Policies;

use App\Models\Conversation;
use App\Models\User;

class ConversationPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('message.view');
    }

    public function view(User $user, Conversation $conversation): bool
    {
        return $user->tenant_id === $conversation->tenant_id
            && $user->can('message.view')
            && $conversation->participants()->whereKey($user->id)->exists();
    }

    public function create(User $user): bool
    {
        return $user->can('message.send');
    }
}
