<?php

namespace App\Notifications\Channels;

use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FirebaseNotification;
use Throwable;

/**
 * Canal Firebase Cloud Messaging, via l'API HTTP v1 (kreait/laravel-firebase)
 * — l'ancienne API "legacy" à clé serveur simple (FCM_SERVER_KEY) a été
 * fermée par Google ; l'authentification se fait désormais avec un compte
 * de service (voir FIREBASE_CREDENTIALS dans .env, docs/PRODUCT_ARCHITECTURE.md §16).
 *
 * Sans FIREBASE_CREDENTIALS configurée (dev/tests), l'envoi est
 * silencieusement ignoré — l'historique reste disponible via le canal
 * `database`.
 */
class FcmChannel
{
    public function send(mixed $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toFcm')) {
            return;
        }

        if (! config('firebase.projects.app.credentials')) {
            Log::warning('FIREBASE_CREDENTIALS non configurée : notification FCM ignorée');

            return;
        }

        $tokens = $notifiable->deviceTokens()->pluck('fcm_token');

        if ($tokens->isEmpty()) {
            return;
        }

        $payload = $notification->toFcm($notifiable);

        try {
            $messaging = app(Messaging::class);
        } catch (Throwable $e) {
            Log::warning('Firebase Messaging indisponible', ['error' => $e->getMessage()]);

            return;
        }

        foreach ($tokens as $token) {
            try {
                $messaging->send(
                    CloudMessage::withTarget('token', $token)
                        ->withNotification(FirebaseNotification::create($payload['title'], $payload['body']))
                        ->withData(array_map('strval', $payload['data'] ?? []))
                );
            } catch (Throwable $e) {
                Log::warning('Échec envoi FCM', ['token' => $token, 'error' => $e->getMessage()]);
            }
        }
    }
}
