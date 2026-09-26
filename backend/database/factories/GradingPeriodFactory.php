<?php

namespace Database\Factories;

use App\Models\GradingPeriod;
use App\Models\SchoolYear;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<GradingPeriod>
 */
class GradingPeriodFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'school_year_id' => SchoolYear::factory(),
            'label' => 'Trimestre 1',
        ];
    }
}
