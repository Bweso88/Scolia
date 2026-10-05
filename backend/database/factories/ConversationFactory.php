<?php

namespace Database\Factories;

use App\Models\Conversation;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Conversation>
 */
class ConversationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'type' => 'direct',
            'created_by_user_id' => User::factory(),
        ];
    }
}
