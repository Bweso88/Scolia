<?php

namespace App\Notifications;

use App\Models\Homework;
use App\Notifications\Concerns\RespectsNotificationPreferences;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class NewHomeworkNotification extends Notification implements ShouldQueue
{
    use Queueable, RespectsNotificationPreferences;

    public function __construct(public Homework $homework) {}

    public function category(): string
    {
        return 'devoir';
    }

    public function toDatabase(mixed $notifiable): array
    {
        return [
            'type' => 'homework',
            'id' => $this->homework->id,
            'title' => 'Nouveau devoir',
            'body' => $this->homework->title,
        ];
    }

    public function toFcm(mixed $notifiable): array
    {
        return [
            'title' => 'Nouveau devoir',
            'body' => $this->homework->title,
            'data' => ['type' => 'homework', 'id' => (string) $this->homework->id],
        ];
    }
}
