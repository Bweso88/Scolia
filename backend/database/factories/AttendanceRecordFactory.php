<?php

namespace Database\Factories;

use App\Models\AttendanceRecord;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AttendanceRecord>
 */
class AttendanceRecordFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'student_id' => Student::factory(),
            'type' => fake()->randomElement(['absence', 'retard']),
            'date' => fake()->dateTimeBetween('-1 month', 'now'),
            'recorded_by_user_id' => User::factory(),
        ];
    }
}
