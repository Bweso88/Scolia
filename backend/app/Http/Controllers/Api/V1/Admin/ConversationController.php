<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreConversationRequest;
use App\Http\Resources\Api\V1\ConversationResource;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class ConversationController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', Conversation::class);

        $conversations = Conversation::query()
            ->whereHas('participants', fn ($q) => $q->whereKey(request()->user()->id))
            ->with(['participants', 'messages'])
            ->latest('updated_at')
            ->paginate();

        return ConversationResource::collection($conversations);
    }

    public function store(StoreConversationRequest $request)
    {
        $conversation = DB::transaction(function () use ($request) {
            $conversation = Conversation::create([
                'type' => 'direct',
                'subject' => $request->validated('subject'),
                'created_by_user_id' => $request->user()->id,
                'student_id' => $request->validated('student_id'),
            ]);

            $conversation->participants()->attach([
                $request->user()->id => ['role_in_thread' => $this->roleInThread($request->user()), 'tenant_id' => $conversation->tenant_id],
            ]);

            $target = User::findOrFail($request->validated('participant_user_id'));
            $conversation->participants()->attach([
                $target->id => ['role_in_thread' => $this->roleInThread($target), 'tenant_id' => $conversation->tenant_id],
            ]);

            $conversation->messages()->create([
                'sender_user_id' => $request->user()->id,
                'body' => $request->validated('body'),
            ]);

            return $conversation;
        });

        return new ConversationResource($conversation->load(['participants', 'messages']));
    }

    public function show(Conversation $conversation)
    {
        $this->authorize('view', $conversation);

        return new ConversationResource($conversation->load(['participants', 'messages.sender']));
    }

    private function roleInThread(User $user): string
    {
        return match (true) {
            $user->hasRole('teacher') => 'teacher',
            $user->hasRole('parent') => 'parent',
            default => 'admin',
        };
    }
}
