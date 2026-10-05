<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SchoolClass>
 */
class SchoolClassFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'school_year_id' => SchoolYear::factory(),
            'name' => fake()->randomElement(['CP1', 'CP2', 'CE1', 'CE2', 'CM1', 'CM2']),
        ];
    }
}
