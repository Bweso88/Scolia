<?php

namespace App\Notifications;

use App\Models\Announcement;
use App\Notifications\Concerns\RespectsNotificationPreferences;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Str;

class NewAnnouncementNotification extends Notification implements ShouldQueue
{
    use Queueable, RespectsNotificationPreferences;

    public function __construct(public Announcement $announcement) {}

    public function category(): string
    {
        return 'annonce';
    }

    public function toDatabase(mixed $notifiable): array
    {
        return [
            'type' => 'announcement',
            'id' => $this->announcement->id,
            'title' => $this->announcement->title,
            'body' => Str::limit($this->announcement->body, 80),
        ];
    }

    public function toFcm(mixed $notifiable): array
    {
        return [
            'title' => $this->announcement->title,
            'body' => Str::limit($this->announcement->body, 80),
            'data' => ['type' => 'announcement', 'id' => (string) $this->announcement->id],
        ];
    }
}
