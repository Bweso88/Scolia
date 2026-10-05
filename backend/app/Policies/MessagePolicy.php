<?php

namespace App\Policies;

use App\Models\Conversation;
use App\Models\User;

class MessagePolicy
{
    /**
     * Autorisé via `$this->authorize('create', [Message::class, $conversation])`
     * — seul un participant de la conversation peut y écrire.
     */
    public function create(User $user, Conversation $conversation): bool
    {
        return $user->tenant_id === $conversation->tenant_id
            && $user->can('message.send')
            && $conversation->participants()->whereKey($user->id)->exists();
    }
}
