<?php

namespace Database\Factories;

use App\Models\BehaviorObservation;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<BehaviorObservation>
 */
class BehaviorObservationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'student_id' => Student::factory(),
            'author_user_id' => User::factory(),
            'category' => fake()->randomElement(['positive', 'discipline', 'participation', 'incident', 'note_generale']),
            'title' => fake()->sentence(4),
            'description' => fake()->sentence(),
            'occurred_at' => now(),
            'visible_to_parent' => true,
        ];
    }
}
