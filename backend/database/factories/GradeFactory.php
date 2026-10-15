<?php

namespace Database\Factories;

use App\Models\Grade;
use App\Models\GradingPeriod;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Grade>
 */
class GradeFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'student_id' => Student::factory(),
            'subject_id' => Subject::factory(),
            'grading_period_id' => GradingPeriod::factory(),
            'score' => fake()->randomFloat(2, 5, 20),
            'max_score' => 20,
            'coefficient' => 1,
            'entered_by_user_id' => User::factory(),
        ];
    }
}
