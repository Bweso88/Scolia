<?php

namespace Database\Factories;

use App\Models\Homework;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Homework>
 */
class HomeworkFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'school_class_id' => SchoolClass::factory(),
            'subject_id' => Subject::factory(),
            'teacher_id' => Teacher::factory(),
            'title' => 'Exercices '.fake()->numberBetween(1, 10).' à '.fake()->numberBetween(11, 20),
            'instructions' => fake()->sentence(),
            'due_date' => fake()->dateTimeBetween('now', '+2 weeks'),
            'published_at' => now(),
        ];
    }
}
