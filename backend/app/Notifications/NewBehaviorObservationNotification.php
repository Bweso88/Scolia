<?php

namespace App\Notifications;

use App\Models\BehaviorObservation;
use App\Notifications\Concerns\RespectsNotificationPreferences;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class NewBehaviorObservationNotification extends Notification implements ShouldQueue
{
    use Queueable, RespectsNotificationPreferences;

    public function __construct(public BehaviorObservation $observation) {}

    public function category(): string
    {
        return 'comportement';
    }

    public function toDatabase(mixed $notifiable): array
    {
        return [
            'type' => 'behavior',
            'id' => $this->observation->id,
            'title' => 'Nouvelle observation',
            'body' => $this->observation->title,
        ];
    }

    public function toFcm(mixed $notifiable): array
    {
        return [
            'title' => 'Nouvelle observation',
            'body' => $this->observation->title,
            'data' => ['type' => 'behavior', 'id' => (string) $this->observation->id],
        ];
    }
}
