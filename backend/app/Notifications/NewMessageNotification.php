<?php

namespace App\Notifications;

use App\Models\Message;
use App\Notifications\Concerns\RespectsNotificationPreferences;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Str;

class NewMessageNotification extends Notification
{
    use RespectsNotificationPreferences;

    public function __construct(public Message $message) {}

    public function category(): string
    {
        return 'message';
    }

    public function toDatabase(mixed $notifiable): array
    {
        return [
            'type' => 'message',
            'id' => $this->message->conversation_id,
            'title' => 'Nouveau message de '.$this->message->sender->name,
            'body' => Str::limit($this->message->body, 80),
        ];
    }

    public function toFcm(mixed $notifiable): array
    {
        return [
            'title' => 'Nouveau message de '.$this->message->sender->name,
            'body' => Str::limit($this->message->body, 80),
            'data' => ['type' => 'conversation', 'id' => (string) $this->message->conversation_id],
        ];
    }
}
