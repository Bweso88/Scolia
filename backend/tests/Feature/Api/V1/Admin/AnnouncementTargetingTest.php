<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * docs/PRODUCT_ARCHITECTURE.md §8 : une annonce ciblée sur une classe ne
 * doit être visible que par les parents ayant un enfant dans cette classe.
 */
class AnnouncementTargetingTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_class_targeted_announcement_is_only_visible_to_that_classs_parents(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $targetedClass = SchoolClass::factory()->for($tenant)->create();
        $otherClass = SchoolClass::factory()->for($tenant)->create();

        $concernedParent = User::factory()->for($tenant)->create();
        $concernedParent->assignRole('parent');
        $concernedChild = Student::factory()->for($tenant)->for($targetedClass, 'schoolClass')->create();
        $concernedChild->guardians()->attach($concernedParent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $unconcernedParent = User::factory()->for($tenant)->create();
        $unconcernedParent->assignRole('parent');
        $unconcernedChild = Student::factory()->for($tenant)->for($otherClass, 'schoolClass')->create();
        $unconcernedChild->guardians()->attach($unconcernedParent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'Réunion de classe',
                'body' => 'Réunion de parents jeudi 18h.',
                'category' => 'reunion',
                'targets' => [
                    ['target_type' => 'school_class', 'target_id' => $targetedClass->id],
                ],
            ])
            ->assertCreated();

        $announcementId = $response->json('data.id');

        $this->actingAs($concernedParent, 'sanctum')
            ->getJson("/api/v1/admin/announcements/{$announcementId}")
            ->assertOk();

        $this->actingAs($unconcernedParent, 'sanctum')
            ->getJson("/api/v1/admin/announcements/{$announcementId}")
            ->assertForbidden();
    }
}
