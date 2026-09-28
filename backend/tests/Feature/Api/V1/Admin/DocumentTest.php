<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * docs/PRODUCT_ARCHITECTURE.md §17 : les documents sont stockés hors du
 * webroot et servis uniquement via une URL signée à courte durée de vie.
 */
class DocumentTest extends TestCase
{
    use RefreshDatabase;

    public function test_an_admin_can_upload_a_document_and_a_parent_can_download_it_via_signed_url(): void
    {
        Storage::fake('local');

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/documents', [
                'title' => 'Règlement intérieur',
                'category' => 'reglement',
                'visible_to' => 'all',
                'file' => UploadedFile::fake()->create('reglement.pdf', 500, 'application/pdf'),
            ])
            ->assertCreated();

        $documentId = $response->json('data.id');

        $show = $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/admin/documents/{$documentId}")
            ->assertOk();

        $downloadUrl = $show->json('download_url');
        $this->assertNotEmpty($downloadUrl);

        // La route signée ne nécessite pas de jeton d'authentification.
        $this->get($downloadUrl)->assertOk();
        $this->get(str_replace('signature=', 'signature=invalid', $downloadUrl))->assertForbidden();
    }

    public function test_a_document_targeted_at_a_specific_student_is_hidden_from_unrelated_parents(): void
    {
        Storage::fake('local');

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $class = SchoolClass::factory()->for($tenant)->create();

        $concernedParent = User::factory()->for($tenant)->create();
        $concernedParent->assignRole('parent');
        $concernedChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $concernedChild->guardians()->attach($concernedParent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $unrelatedParent = User::factory()->for($tenant)->create();
        $unrelatedParent->assignRole('parent');

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/documents', [
                'title' => 'Convocation',
                'category' => 'autre',
                'visible_to' => 'student',
                'target_id' => $concernedChild->id,
                'file' => UploadedFile::fake()->create('convocation.pdf', 100, 'application/pdf'),
            ])
            ->assertCreated();

        $documentId = $response->json('data.id');

        $this->actingAs($concernedParent, 'sanctum')
            ->getJson("/api/v1/admin/documents/{$documentId}")
            ->assertOk();

        $this->actingAs($unrelatedParent, 'sanctum')
            ->getJson("/api/v1/admin/documents/{$documentId}")
            ->assertForbidden();
    }
}
