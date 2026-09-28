<?php

namespace App\Notifications;

use App\Models\AttendanceRecord;
use App\Notifications\Concerns\RespectsNotificationPreferences;
use Illuminate\Notifications\Notification;

class AbsenceRecordedNotification extends Notification
{
    use RespectsNotificationPreferences;

    public function __construct(public AttendanceRecord $record) {}

    public function category(): string
    {
        return 'absence';
    }

    public function toDatabase(mixed $notifiable): array
    {
        return [
            'type' => 'attendance',
            'id' => $this->record->id,
            'title' => $this->title(),
            'body' => 'Le '.$this->record->date->toDateString(),
        ];
    }

    public function toFcm(mixed $notifiable): array
    {
        return [
            'title' => $this->title(),
            'body' => 'Le '.$this->record->date->toDateString(),
            'data' => ['type' => 'attendance', 'id' => (string) $this->record->id],
        ];
    }

    private function title(): string
    {
        return $this->record->type === 'absence'
            ? 'Votre enfant est absent'
            : 'Votre enfant est en retard';
    }
}
