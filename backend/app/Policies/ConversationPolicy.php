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

    /**
     * Masquer la conversation de sa propre liste (parent ou enseignant) :
     * même règle que pour la consulter.
     */
    public function archive(User $user, Conversation $conversation): bool
    {
        return $this->view($user, $conversation);
    }

    /**
     * Supprimer la conversation (pour tous ses participants) : n'importe
     * quel participant peut le faire, comme pour un fil qu'on ne veut plus
     * garder.
     */
    public function delete(User $user, Conversation $conversation): bool
    {
        return $this->view($user, $conversation);
    }
}
