<?php

namespace Database\Factories;

use App\Models\ParentIdentity;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ParentIdentity>
 */
class ParentIdentityFactory extends Factory
{
    public function definition(): array
    {
        return [
            'full_name' => fake()->name(),
            'canonical_email' => fake()->unique()->safeEmail(),
            'canonical_phone' => fake()->phoneNumber(),
        ];
    }
}
