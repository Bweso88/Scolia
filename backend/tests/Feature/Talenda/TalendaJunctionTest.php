<?php

namespace Tests\Feature\Talenda;

use App\Filament\Pages\TalendaConnection;
use App\Filament\Resources\Students\StudentResource;
use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Student;
use App\Models\StudentGuardian;
use App\Models\Subject;
use App\Models\TeacherAssignment;
use App\Models\Tenant;
use App\Models\TenantSetting;
use App\Models\User;
use App\Services\Talenda\SyncFromTalenda;
use App\Services\Talenda\UnlinkFromTalenda;
use App\Support\Talenda\ManagedByTalendaException;
use App\Support\Talenda\TalendaUnavailable;
use App\Support\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Livewire\Livewire;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Jonction avec Talenda, référence de l'école (docs/JONCTION_TALENDA.md).
 */
class TalendaJunctionTest extends TestCase
{
    use RefreshDatabase;

    private const URL = 'https://talenda.test/api/integration/v1';

    private Tenant $tenant;

    /**
     * @var array<string, mixed>
     */
    private array $talendaSnapshot = [];

    private bool $talendaDown = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = Tenant::factory()->create(['slug' => 'lycee-a']);
        TenantSetting::query()->forceCreate([
            'tenant_id' => $this->tenant->id,
            'display_name' => 'Lycée A',
            'talenda_url' => self::URL,
            'talenda_token' => 'tlnd_secret',
        ]);
    }

    public function test_it_imports_the_school_from_talenda_and_adopts_records_already_in_scolia(): void
    {
        // Saisis à la main avant la jonction : repris, pas dupliqués.
        $settings = TenantSetting::query()->sole();
        $settings->update(['talenda_token' => null]);
        $this->inTenant(function (): void {
            $year = SchoolYear::query()->create(['label' => '2026-2027', 'start_date' => '2026-09-01', 'end_date' => '2027-06-30', 'is_current' => true]);
            $class = SchoolClass::query()->create(['school_year_id' => $year->id, 'name' => '6e A']);
            Student::query()->create(['school_class_id' => $class->id, 'first_name' => 'Grâce', 'last_name' => 'Mabiala', 'enrollment_number' => 'LA-26-0001', 'status' => 'active']);
            User::factory()->for($this->tenant)->create(['name' => 'Prisca M.', 'email' => 'prisca@example.cg', 'phone' => '06 333 33 33']);
        });
        $settings->update(['talenda_token' => 'tlnd_secret']);
        $this->fakeTalenda($this->snapshot());

        $counts = app(SyncFromTalenda::class)->handle($this->tenant);

        $this->assertSame(['students' => 2, 'guardians' => 1, 'teachers' => 1, 'classes' => 1], $counts);

        $this->inTenant(function (): void {
            $this->assertSame(1, SchoolYear::query()->count());
            $this->assertSame(1, SchoolClass::query()->count());
            $this->assertSame(2, Student::query()->count());

            $grace = Student::query()->where('talenda_uuid', 'stu-1')->sole();
            $this->assertSame('LA-26-0001', $grace->enrollment_number);
            $this->assertSame('f', $grace->gender);

            $parent = User::query()->where('talenda_guardian_uuid', 'gua-1')->sole();
            $this->assertSame('prisca@example.cg', $parent->email);
            $this->assertSame('+242063333333', $parent->phone);
            $this->assertSame('acc-parent', $parent->talenda_account_uuid);
            $this->assertTrue($parent->hasRole('parent'));
            $this->assertSame(['mère', 'mère'], StudentGuardian::query()->where('user_id', $parent->id)->pluck('relationship_type')->all());

            $teacher = User::query()->where('talenda_account_uuid', 'acc-teacher')->sole();
            $this->assertNull($teacher->email);
            $this->assertTrue($teacher->hasRole('teacher'));
            $this->assertSame($teacher->teacher->id, SchoolClass::query()->sole()->homeroom_teacher_id);
            $this->assertSame(1, TeacherAssignment::query()->count());
            $this->assertSame('Mathématiques', Subject::query()->sole()->name);
        });

        $this->assertNotNull(TenantSetting::query()->sole()->talenda_synced_at);
    }

    public function test_what_disappears_from_talenda_is_deactivated_not_deleted(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);

        $snapshot = $this->snapshot();
        $snapshot['guardians'][0]['children'] = [$snapshot['guardians'][0]['children'][0]];
        $snapshot['teaching'] = [];
        $this->fakeTalenda($snapshot);

        app(SyncFromTalenda::class)->handle($this->tenant);

        $this->inTenant(function (): void {
            $this->assertSame(1, StudentGuardian::query()->count());
            $this->assertSame(0, TeacherAssignment::query()->count());
        });

        $snapshot['students'] = [$snapshot['students'][0]];
        $snapshot['guardians'] = [];
        $this->fakeTalenda($snapshot);

        app(SyncFromTalenda::class)->handle($this->tenant);

        $this->inTenant(function (): void {
            $this->assertSame('transferred', Student::query()->where('talenda_uuid', 'stu-2')->sole()->status);
            $this->assertSame(2, Student::query()->count());
            $this->assertFalse(User::query()->where('talenda_guardian_uuid', 'gua-1')->sole()->is_active);
        });
    }

    public function test_records_from_talenda_are_read_only_in_scolia_except_scolia_own_fields(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);
        $admin = $this->schoolAdmin();
        $student = $this->inTenant(fn () => Student::query()->where('talenda_uuid', 'stu-1')->sole());

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/students/{$student->id}", ['first_name' => 'Autre'])
            ->assertStatus(409)
            ->assertJsonPath('message', fn (string $message) => str_starts_with($message, 'Géré dans Talenda'));

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/students/{$student->id}")->assertStatus(409);

        // L'activation de l'enfant est propre à Scolia.
        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/students/{$student->id}/activation", ['active' => true])
            ->assertOk();

        $this->actingAs($admin);
        $this->inTenant(function (): void {
            $this->assertFalse(StudentResource::canCreate());
            $this->expectException(ManagedByTalendaException::class);
            Subject::query()->create(['name' => 'Latin']);
        });
    }

    public function test_a_parent_from_talenda_logs_in_with_their_phone_and_talenda_password(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);

        $this->fakeCredentials();

        $this->postJson('/api/v1/auth/login', ['login' => '06 333 33 33', 'password' => 'mot-de-passe-talenda'])
            ->assertOk()
            ->assertJsonPath('user.roles', ['parent']);

        $this->postJson('/api/v1/auth/login', ['login' => '063333333', 'password' => 'mauvais'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email' => 'Ces identifiants ne correspondent à aucun compte.']);

        Http::assertSent(fn (Request $request) => $request->hasHeader('Authorization', 'Bearer tlnd_secret') && $request['login'] === '06 333 33 33');
    }

    public function test_login_says_so_when_talenda_does_not_answer(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);
        Http::fake([self::URL.'/credentials/check' => Http::response('', 500)]);

        $this->postJson('/api/v1/auth/login', ['login' => '+242063333333', 'password' => 'x'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.email.0', fn (string $message) => str_contains($message, 'ne répond pas'));
    }

    public function test_a_talenda_outage_does_not_lock_out_users_who_already_logged_in(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);
        $this->fakeCredentials();

        $this->postJson('/api/v1/auth/login', ['login' => '06 333 33 33', 'password' => 'mot-de-passe-talenda'])->assertOk();

        $this->talendaDown = true;

        $this->postJson('/api/v1/auth/login', ['login' => '06 333 33 33', 'password' => 'mot-de-passe-talenda'])->assertOk();
        $this->postJson('/api/v1/auth/login', ['login' => '06 333 33 33', 'password' => 'mauvais'])->assertUnprocessable();

        // Jamais connecté : Scolia n'a aucun mot de passe à comparer.
        $this->postJson('/api/v1/auth/login', ['login' => '+242064444402', 'password' => 'mot-de-passe-talenda'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.email.0', fn (string $message) => str_contains($message, 'ne répond pas'));
    }

    public function test_an_unlinked_school_manages_everything_in_scolia_again(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);
        $this->fakeCredentials();
        $this->postJson('/api/v1/auth/login', ['login' => '06 333 33 33', 'password' => 'mot-de-passe-talenda'])->assertOk();

        $passwords = app(UnlinkFromTalenda::class)->handle($this->tenant);

        // Seul l'enseignant, jamais connecté, reçoit un mot de passe provisoire.
        $this->assertSame(['Jean Okemba'], array_column($passwords, 'name'));
        $this->assertFalse(TenantSetting::query()->sole()->isConnectedToTalenda());

        Http::fake();
        $this->postJson('/api/v1/auth/login', ['login' => '063333333', 'password' => 'mot-de-passe-talenda'])->assertOk();
        $this->postJson('/api/v1/auth/login', ['login' => '+242064444402', 'password' => $passwords[0]['password']])->assertOk();
        $this->artisan('scolia:talenda-sync')->assertSuccessful();
        Http::assertNothingSent();

        $this->actingAs($this->schoolAdmin());
        $this->inTenant(function (): void {
            $this->assertSame(2, Student::query()->count());
            $this->assertTrue(StudentResource::canCreate());
            Student::query()->where('first_name', 'Grâce')->sole()->update(['first_name' => 'Grâce-Divine']);
            $this->assertTrue(Subject::query()->create(['name' => 'Latin'])->exists);
        });
    }

    public function test_a_revoked_key_is_reported_and_changes_nothing(): void
    {
        Http::fake([self::URL.'/snapshot' => Http::response(['message' => 'Clé invalide.'], 401)]);

        $this->artisan('scolia:talenda-sync')->assertFailed();

        $this->assertSame('Clé Talenda refusée : elle a peut-être été révoquée.', TenantSetting::query()->sole()->talenda_sync_error);
        $this->inTenant(fn () => $this->assertSame(0, Student::query()->count()));

        $this->expectException(TalendaUnavailable::class);
        app(SyncFromTalenda::class)->handle($this->tenant);
    }

    public function test_a_school_without_talenda_keeps_managing_everything_in_scolia(): void
    {
        $other = Tenant::factory()->create();
        Http::fake();

        $this->artisan('scolia:talenda-sync', ['tenant' => $other->slug])->assertSuccessful();

        Http::assertNothingSent();
        app(TenantContext::class)->set($other);
        $this->assertTrue(Subject::query()->create(['name' => 'Latin'])->exists);
    }

    public function test_the_school_admin_connects_scolia_to_talenda_from_the_admin_panel(): void
    {
        TenantSetting::query()->sole()->update(['talenda_url' => null, 'talenda_token' => null]);
        $this->fakeTalenda($this->snapshot());
        $this->actingAs($this->schoolAdmin());
        app(TenantContext::class)->set($this->tenant);

        Livewire::test(TalendaConnection::class)
            ->assertSee('Non reliée')
            ->fillForm(['talenda_url' => self::URL.'/', 'talenda_token' => 'tlnd_secret'])
            ->callAction('save')
            ->assertNotified('Synchronisation terminée');

        $settings = TenantSetting::query()->sole();
        $this->assertSame(self::URL, $settings->talenda_url);
        $this->assertSame('tlnd_secret', $settings->talenda_token);
        $this->assertSame(2, Student::query()->count());
    }

    public function test_the_school_admin_unlinks_from_the_admin_panel_and_downloads_temporary_passwords(): void
    {
        $this->fakeTalenda($this->snapshot());
        app(SyncFromTalenda::class)->handle($this->tenant);
        $this->actingAs($this->schoolAdmin());
        app(TenantContext::class)->set($this->tenant);

        Livewire::test(TalendaConnection::class)
            ->callAction('unlink')
            ->assertFileDownloaded('mots-de-passe-provisoires.csv')
            ->assertNotified('École déliée de Talenda');

        $this->assertFalse(TenantSetting::query()->sole()->isConnectedToTalenda());
    }

    /**
     * Talenda accepte « mot-de-passe-talenda » pour le parent et
     * l'enseignant, sauf pendant une panne ($talendaDown).
     */
    private function fakeCredentials(): void
    {
        Http::fake([
            self::URL.'/credentials/check' => function (Request $request) {
                if ($this->talendaDown) {
                    return Http::response('', 503);
                }

                $accounts = ['06 333 33 33' => 'acc-parent', '063333333' => 'acc-parent', '+242064444402' => 'acc-teacher'];

                return $request['password'] === 'mot-de-passe-talenda' && isset($accounts[$request['login']])
                    ? Http::response(['account_uuid' => $accounts[$request['login']], 'name' => 'Compte', 'phone' => null, 'email' => null, 'must_change_password' => false, 'roles' => []])
                    : Http::response(['message' => 'Identifiants incorrects.', 'errors' => ['login' => ['Identifiants incorrects.']]], 422);
            },
        ]);
    }

    /**
     * @param  array<string, mixed>  $snapshot
     */
    private function fakeTalenda(array $snapshot): void
    {
        $this->talendaSnapshot = $snapshot;
        Http::fake([self::URL.'/snapshot' => fn () => Http::response($this->talendaSnapshot)]);
    }

    /**
     * @return array<string, mixed>
     */
    private function snapshot(): array
    {
        return [
            'generated_at' => '2026-11-16T09:00:00+00:00',
            'school' => ['uuid' => 'sch-1', 'name' => 'Lycée A', 'timezone' => 'Africa/Brazzaville'],
            'school_year' => ['uuid' => 'year-1', 'name' => '2026-2027', 'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30'],
            'subjects' => [['uuid' => 'sub-1', 'code' => 'MATH', 'name' => 'Mathématiques']],
            'classes' => [['uuid' => 'cls-1', 'name' => '6e A', 'level' => 'Sixième', 'level_code' => '6E', 'stream' => null, 'head_teacher_uuid' => 'stf-1']],
            'staff' => [
                ['uuid' => 'stf-1', 'first_name' => 'Jean', 'last_name' => 'Okemba', 'full_name' => 'Jean Okemba', 'position' => 'teacher', 'phone' => '+242064444402', 'email' => null, 'is_active' => true, 'account_uuid' => 'acc-teacher'],
                ['uuid' => 'stf-2', 'first_name' => 'Rose', 'last_name' => 'Ngoma', 'full_name' => 'Rose Ngoma', 'position' => 'cashier', 'phone' => '+242064444410', 'email' => null, 'is_active' => true, 'account_uuid' => null],
            ],
            'teaching' => [['class_uuid' => 'cls-1', 'subject_uuid' => 'sub-1', 'teacher_uuid' => 'stf-1', 'coefficient' => 4.0]],
            'students' => [
                ['uuid' => 'stu-1', 'registration_number' => 'LA-26-0001', 'last_name' => 'Mabiala', 'first_names' => 'Grâce', 'gender' => 'F', 'birth_date' => '2014-03-02', 'class_uuid' => 'cls-1'],
                ['uuid' => 'stu-2', 'registration_number' => 'LA-26-0002', 'last_name' => 'Mabiala', 'first_names' => 'Exaucé', 'gender' => 'M', 'birth_date' => '2015-05-12', 'class_uuid' => 'cls-1'],
            ],
            'guardians' => [[
                'uuid' => 'gua-1', 'last_name' => 'Mabiala', 'first_names' => 'Prisca', 'full_name' => 'Prisca Mabiala',
                'phone' => '+242063333333', 'email' => null, 'account_uuid' => 'acc-parent',
                'children' => [
                    ['student_uuid' => 'stu-1', 'relationship' => 'mother', 'is_primary_contact' => true],
                    ['student_uuid' => 'stu-2', 'relationship' => 'mother', 'is_primary_contact' => true],
                ],
            ]],
        ];
    }

    private function schoolAdmin(): User
    {
        app(PermissionRegistrar::class)->setPermissionsTeamId($this->tenant->id);
        $admin = User::factory()->for($this->tenant)->create();
        $admin->assignRole('school_admin');

        return $admin;
    }

    /**
     * @template T
     *
     * @param  callable(): T  $callback
     * @return T
     */
    private function inTenant(callable $callback): mixed
    {
        $context = app(TenantContext::class);
        $previous = $context->get();
        $context->set($this->tenant);
        app(PermissionRegistrar::class)->setPermissionsTeamId($this->tenant->id);

        try {
            return $callback();
        } finally {
            $context->set($previous);
        }
    }
}
