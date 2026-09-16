<?php

namespace Database\Factories;

use App\Models\SchoolYear;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SchoolYear>
 */
class SchoolYearFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'label' => '2026-2027',
            'start_date' => '2026-09-01',
            'end_date' => '2027-06-30',
            'is_current' => true,
        ];
    }
}
