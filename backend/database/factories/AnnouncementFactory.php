<?php

namespace Database\Factories;

use App\Models\Announcement;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Announcement>
 */
class AnnouncementFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'author_user_id' => User::factory(),
            'title' => fake()->sentence(3),
            'body' => fake()->paragraph(),
            'category' => 'info',
            'published_at' => now(),
        ];
    }
}
