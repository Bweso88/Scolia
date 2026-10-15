<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Student>
 */
class StudentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'school_class_id' => SchoolClass::factory(),
            'first_name' => fake()->firstName(),
            'last_name' => fake()->lastName(),
            'birth_date' => fake()->dateTimeBetween('-12 years', '-6 years'),
            'gender' => fake()->randomElement(['m', 'f']),
            'status' => 'active',
            'activated_at' => now(),
        ];
    }

    /**
     * Enfant dont l'abonnement n'a pas (encore) été activé par le parent
     * (docs/PRODUCT_ARCHITECTURE.md §18) : utile pour tester la
     * restriction d'accès côté parent.
     */
    public function inactive(): static
    {
        return $this->state(['activated_at' => null]);
    }
}
