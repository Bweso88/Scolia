<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\Teacher;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * docs/PRODUCT_ARCHITECTURE.md §7/§15 : un parent ne doit jamais pouvoir
 * contacter directement un enseignant sans autorisation de l'école.
 */
class MessagingPermissionTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_parent_cannot_start_a_conversation_with_an_unauthorized_teacher(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');
        Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);
        // Aucune messaging_permission créée : can_be_contacted_directly est donc absent (= non autorisé).

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/conversations', [
                'participant_user_id' => $teacherUser->id,
                'body' => 'Bonjour, pouvez-vous me recevoir ?',
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('participant_user_id');
    }

    public function test_a_parent_can_message_a_teacher_once_the_school_authorizes_it(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/teachers/{$teacher->id}/messaging-permission", [
                'can_be_contacted_directly' => true,
            ])
            ->assertOk();

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/conversations', [
                'participant_user_id' => $teacherUser->id,
                'body' => 'Bonjour, pouvez-vous me recevoir ?',
            ])
            ->assertCreated();
    }
}
