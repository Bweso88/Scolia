<?php

namespace Database\Factories;

use App\Models\Teacher;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Teacher>
 */
class TeacherFactory extends Factory
{
    public function definition(): array
    {
        $tenant = Tenant::factory()->create();

        return [
            'tenant_id' => $tenant->id,
            'user_id' => User::factory()->for($tenant, 'tenant'),
        ];
    }
}
