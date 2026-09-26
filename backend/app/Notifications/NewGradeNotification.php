<?php

namespace App\Notifications;

use App\Models\Grade;
use App\Notifications\Concerns\RespectsNotificationPreferences;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class NewGradeNotification extends Notification implements ShouldQueue
{
    use Queueable, RespectsNotificationPreferences;

    public function __construct(public Grade $grade) {}

    public function category(): string
    {
        return 'note';
    }

    public function toDatabase(mixed $notifiable): array
    {
        return [
            'type' => 'grade',
            'id' => $this->grade->id,
            'title' => 'Nouvelle note',
            'body' => $this->grade->subject?->name.' : '.$this->grade->score.'/'.$this->grade->max_score,
        ];
    }

    public function toFcm(mixed $notifiable): array
    {
        return [
            'title' => 'Nouvelle note',
            'body' => $this->grade->subject?->name.' : '.$this->grade->score.'/'.$this->grade->max_score,
            'data' => ['type' => 'grade', 'id' => (string) $this->grade->id],
        ];
    }
}
