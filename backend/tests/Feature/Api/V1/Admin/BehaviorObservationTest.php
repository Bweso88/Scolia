<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\BehaviorObservation;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class BehaviorObservationTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_teacher_can_publish_an_observation_and_the_parent_sees_it(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, [
            'tenant_id' => $tenant->id,
            'relationship_type' => 'parent',
            'is_primary_contact' => true,
        ]);

        $response = $this->actingAs($teacher, 'sanctum')
            ->postJson('/api/v1/admin/behavior-observations', [
                'student_id' => $student->id,
                'category' => 'positive',
                'title' => 'Participation excellente en classe',
            ])
            ->assertCreated();

        $observationId = $response->json('data.id');

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/admin/behavior-observations/{$observationId}")
            ->assertOk();
    }

    public function test_a_parent_cannot_delete_an_observation(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $observation = BehaviorObservation::factory()->for($tenant)->create(['author_user_id' => $teacher->id]);

        $this->actingAs($parent, 'sanctum')
            ->deleteJson("/api/v1/admin/behavior-observations/{$observation->id}")
            ->assertForbidden();
    }

    public function test_a_teacher_can_delete_their_own_observation_but_not_a_colleagues(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $author = User::factory()->for($tenant)->create();
        $author->assignRole('teacher');

        $colleague = User::factory()->for($tenant)->create();
        $colleague->assignRole('teacher');

        $observation = BehaviorObservation::factory()->for($tenant)->create(['author_user_id' => $author->id]);

        $this->actingAs($colleague, 'sanctum')
            ->deleteJson("/api/v1/admin/behavior-observations/{$observation->id}")
            ->assertForbidden();

        $this->actingAs($author, 'sanctum')
            ->deleteJson("/api/v1/admin/behavior-observations/{$observation->id}")
            ->assertNoContent();
    }
}
