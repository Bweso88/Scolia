<?php

namespace Database\Factories;

use App\Models\Document;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Document>
 */
class DocumentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tenant_id' => Tenant::factory(),
            'title' => fake()->sentence(3),
            'category' => 'circulaire',
            'file_path' => 'tenants/1/documents/'.fake()->uuid().'.pdf',
            'visible_to' => 'all',
            'uploaded_by_user_id' => User::factory(),
        ];
    }
}
