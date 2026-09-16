<?php

namespace App\Notifications\Channels;

use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Canal Firebase Cloud Messaging (docs/PRODUCT_ARCHITECTURE.md §16).
 *
 * Sans FCM_SERVER_KEY configurée (dev/tests), l'envoi est silencieusement
 * ignoré — l'historique reste disponible via le canal `database`. En
 * production, définir FCM_SERVER_KEY suffit à activer le push réel, sans
 * changement de code applicatif.
 */
class FcmChannel
{
    public function send(mixed $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toFcm')) {
            return;
        }

        $serverKey = config('services.fcm.server_key');

        if (! $serverKey) {
            return;
        }

        $tokens = $notifiable->deviceTokens()->pluck('fcm_token');

        if ($tokens->isEmpty()) {
            return;
        }

        $payload = $notification->toFcm($notifiable);

        foreach ($tokens as $token) {
            $response = Http::withToken($serverKey)->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $token,
                'notification' => [
                    'title' => $payload['title'],
                    'body' => $payload['body'],
                ],
                'data' => $payload['data'] ?? [],
            ]);

            if ($response->failed()) {
                Log::warning('Échec envoi FCM', ['token' => $token, 'status' => $response->status()]);
            }
        }
    }
}
