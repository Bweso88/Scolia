<?php

namespace App\Notifications\Concerns;

use App\Notifications\Channels\FcmChannel;

/**
 * Chaque catégorie métier (devoir, absence, message, annonce...) peut être
 * désactivée indépendamment par l'utilisateur (docs/PRODUCT_ARCHITECTURE.md
 * §16, table notification_preferences). L'historique en base reste
 * toujours alimenté ; seul le push est filtré.
 */
trait RespectsNotificationPreferences
{
    public function via(mixed $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->wantsNotification($this->category(), 'push')) {
            $channels[] = FcmChannel::class;
        }

        return $channels;
    }

    abstract public function category(): string;
}
