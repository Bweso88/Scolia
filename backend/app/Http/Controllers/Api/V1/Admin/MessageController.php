<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreMessageRequest;
use App\Http\Resources\Api\V1\MessageResource;
use App\Models\Conversation;

class MessageController extends Controller
{
    public function index(Conversation $conversation)
    {
        $this->authorize('view', $conversation);

        $messages = $conversation->messages()->with('sender')->orderBy('created_at')->paginate();

        return MessageResource::collection($messages);
    }

    public function store(StoreMessageRequest $request, Conversation $conversation)
    {
        $message = $conversation->messages()->create([
            'sender_user_id' => $request->user()->id,
            'body' => $request->validated('body'),
        ]);

        $conversation->touch();

        return new MessageResource($message->load('sender'));
    }
}
