<?php

namespace App\Services\Talenda;

use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Student;
use App\Models\StudentGuardian;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherAssignment;
use App\Models\Tenant;
use App\Models\TenantSetting;
use App\Models\User;
use App\Support\Talenda\PhoneNumber;
use App\Support\Talenda\TalendaClient;
use App\Support\Talenda\TalendaSync;
use App\Support\Talenda\TalendaUnavailable;
use App\Support\Tenancy\TenantContext;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Spatie\Permission\PermissionRegistrar;

/**
 * Met une école Scolia en phase avec Talenda, la référence pour les
 * élèves, classes, matières, enseignants et parents
 * (docs/JONCTION_TALENDA.md).
 *
 * Rapprochement par uuid Talenda ; à la première synchronisation, les
 * fiches déjà saisies dans Scolia sont reprises (même nom de matière, même
 * classe, même matricule, même téléphone…) plutôt que dupliquées. Ce qui
 * disparaît de Talenda est désactivé, jamais supprimé : l'historique de
 * messagerie et le cahier de texte restent intacts.
 */
class SyncFromTalenda
{
    /**
     * @var array<string, int> uuid Talenda → id Scolia
     */
    private array $subjects = [];

    /**
     * @var array<string, int>
     */
    private array $classes = [];

    /**
     * @var array<string, int>
     */
    private array $teachers = [];

    /**
     * @var array<string, int>
     */
    private array $students = [];

    /**
     * @var Collection<int, User>|null
     */
    private ?Collection $tenantUsers = null;

    public function __construct(private readonly TenantContext $tenantContext) {}

    /**
     * @return array{students: int, guardians: int, teachers: int, classes: int}
     *
     * @throws TalendaUnavailable
     */
    public function handle(Tenant $tenant): array
    {
        $previousTenant = $this->tenantContext->get();
        $registrar = app(PermissionRegistrar::class);
        $previousTeam = $registrar->getPermissionsTeamId();

        $this->tenantContext->set($tenant);
        $registrar->setPermissionsTeamId($tenant->id);

        $settings = TenantSetting::query()->sole();

        try {
            $snapshot = (new TalendaClient($settings))->snapshot();

            $counts = TalendaSync::run(fn (): array => DB::transaction(fn (): array => $this->apply($settings, $snapshot)));

            $settings->forceFill(['talenda_synced_at' => now(), 'talenda_sync_error' => null])->save();

            return $counts;
        } catch (TalendaUnavailable $exception) {
            $settings->forceFill(['talenda_sync_error' => $exception->getMessage()])->save();

            throw $exception;
        } finally {
            $this->tenantContext->set($previousTenant);
            $registrar->setPermissionsTeamId($previousTeam);
        }
    }

    /**
     * @param  array<string, mixed>  $snapshot
     * @return array{students: int, guardians: int, teachers: int, classes: int}
     */
    private function apply(TenantSetting $settings, array $snapshot): array
    {
        if ($snapshot['school_year'] === null) {
            throw new TalendaUnavailable('Aucune année scolaire ouverte dans Talenda.');
        }

        $year = $this->syncYear($snapshot['school_year']);
        $settings->forceFill(['current_school_year_id' => $year->id])->save();

        $this->syncSubjects($snapshot['subjects']);
        $this->syncTeachers($snapshot['staff'], $snapshot['teaching'], $snapshot['classes']);
        $this->syncClasses($year, $snapshot['classes']);
        $this->syncTeaching($snapshot['teaching']);
        $this->syncStudents($snapshot['students']);
        $guardians = $this->syncGuardians($snapshot['guardians']);

        return [
            'students' => count($this->students),
            'guardians' => $guardians,
            'teachers' => count($this->teachers),
            'classes' => count($this->classes),
        ];
    }

    /**
     * @param  array{uuid: string, name: string, starts_on: string, ends_on: string}  $data
     */
    private function syncYear(array $data): SchoolYear
    {
        $year = SchoolYear::query()->where('talenda_uuid', $data['uuid'])->first()
            ?? SchoolYear::query()->whereNull('talenda_uuid')->where('label', $data['name'])->first()
            ?? SchoolYear::query()->whereNull('talenda_uuid')->where('is_current', true)->first()
            ?? new SchoolYear;

        $year->forceFill([
            'talenda_uuid' => $data['uuid'],
            'label' => $data['name'],
            'start_date' => $data['starts_on'],
            'end_date' => $data['ends_on'],
            'is_current' => true,
        ])->save();

        SchoolYear::query()->whereKeyNot($year->id)->where('is_current', true)->update(['is_current' => false]);

        return $year;
    }

    /**
     * @param  list<array{uuid: string, name: string}>  $subjects
     */
    private function syncSubjects(array $subjects): void
    {
        foreach ($subjects as $data) {
            $subject = Subject::query()->where('talenda_uuid', $data['uuid'])->first()
                ?? Subject::query()->whereNull('talenda_uuid')->whereRaw('lower(name) = ?', [Str::lower($data['name'])])->first()
                ?? new Subject;

            $subject->forceFill(['talenda_uuid' => $data['uuid'], 'name' => $data['name']])->save();
            $this->subjects[$data['uuid']] = $subject->id;
        }
    }

    /**
     * Seul le personnel enseignant (poste « enseignant », ou présent dans un
     * enseignement ou comme professeur principal) a une fiche Scolia.
     *
     * @param  list<array<string, mixed>>  $staff
     * @param  list<array<string, mixed>>  $teaching
     * @param  list<array<string, mixed>>  $classes
     */
    private function syncTeachers(array $staff, array $teaching, array $classes): void
    {
        $teachingUuids = collect($teaching)->pluck('teacher_uuid')
            ->merge(collect($classes)->pluck('head_teacher_uuid'))
            ->filter()
            ->unique();

        foreach ($staff as $data) {
            if ($data['position'] !== 'teacher' && ! $teachingUuids->contains($data['uuid'])) {
                continue;
            }

            $teacher = Teacher::query()->with('user')->where('talenda_uuid', $data['uuid'])->first();
            $user = $teacher?->user ?? $this->findUser($data['account_uuid'], $data['phone'], $data['email']);

            $user = $this->saveUser($user, [
                'name' => $data['full_name'],
                'phone' => $data['phone'],
                'email' => $data['email'],
                'talenda_account_uuid' => $data['account_uuid'],
                'is_active' => (bool) $data['is_active'],
            ], 'teacher');

            $teacher ??= Teacher::query()->where('user_id', $user->id)->whereNull('talenda_uuid')->first() ?? new Teacher;
            $teacher->forceFill(['talenda_uuid' => $data['uuid'], 'user_id' => $user->id])->save();

            $this->teachers[$data['uuid']] = $teacher->id;
        }

        Teacher::query()
            ->with('user')
            ->whereNotNull('talenda_uuid')
            ->whereNotIn('talenda_uuid', array_keys($this->teachers))
            ->get()
            ->each(fn (Teacher $teacher) => $teacher->user?->forceFill(['is_active' => false])->save());
    }

    /**
     * @param  list<array<string, mixed>>  $classes
     */
    private function syncClasses(SchoolYear $year, array $classes): void
    {
        foreach ($classes as $data) {
            $schoolClass = SchoolClass::query()->where('talenda_uuid', $data['uuid'])->first()
                ?? SchoolClass::query()->whereNull('talenda_uuid')->where('school_year_id', $year->id)->where('name', $data['name'])->first()
                ?? new SchoolClass;

            $schoolClass->forceFill([
                'talenda_uuid' => $data['uuid'],
                'school_year_id' => $year->id,
                'name' => $data['name'],
                'level' => $data['level'],
                'homeroom_teacher_id' => $this->teachers[$data['head_teacher_uuid'] ?? ''] ?? null,
            ])->save();

            $this->classes[$data['uuid']] = $schoolClass->id;
        }
    }

    /**
     * @param  list<array{class_uuid: string, subject_uuid: string, teacher_uuid: ?string}>  $teaching
     */
    private function syncTeaching(array $teaching): void
    {
        $kept = [];

        foreach ($teaching as $data) {
            $teacherId = $this->teachers[$data['teacher_uuid'] ?? ''] ?? null;
            $classId = $this->classes[$data['class_uuid']] ?? null;
            $subjectId = $this->subjects[$data['subject_uuid']] ?? null;

            if ($teacherId === null || $classId === null || $subjectId === null) {
                continue;
            }

            $kept[] = TeacherAssignment::query()->firstOrCreate([
                'teacher_id' => $teacherId,
                'school_class_id' => $classId,
                'subject_id' => $subjectId,
            ])->id;
        }

        // Enseignement retiré dans Talenda : on ne retire que les
        // affectations entre fiches venues de Talenda.
        TeacherAssignment::query()
            ->whereIn('teacher_id', $this->teachers)
            ->whereIn('school_class_id', $this->classes)
            ->whereKeyNot($kept)
            ->delete();
    }

    /**
     * @param  list<array<string, mixed>>  $students
     */
    private function syncStudents(array $students): void
    {
        foreach ($students as $data) {
            $classId = $this->classes[$data['class_uuid']] ?? null;

            if ($classId === null) {
                continue;
            }

            $student = Student::query()->where('talenda_uuid', $data['uuid'])->first()
                ?? $this->adoptStudent($data)
                ?? new Student;

            $student->forceFill([
                'talenda_uuid' => $data['uuid'],
                'school_class_id' => $classId,
                'first_name' => $data['first_names'],
                'last_name' => $data['last_name'],
                'birth_date' => $data['birth_date'],
                'gender' => Str::lower((string) $data['gender']) ?: null,
                'enrollment_number' => $data['registration_number'],
                'status' => 'active',
            ])->save();

            $this->students[$data['uuid']] = $student->id;
        }

        // Élève qui n'est plus inscrit dans Talenda (départ, exclusion…).
        Student::query()
            ->whereNotNull('talenda_uuid')
            ->whereNotIn('talenda_uuid', array_keys($this->students))
            ->where('status', 'active')
            ->get()
            ->each(fn (Student $student) => $student->forceFill(['status' => 'transferred'])->save());
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function adoptStudent(array $data): ?Student
    {
        $candidates = Student::query()->whereNull('talenda_uuid');

        if (filled($data['registration_number'])) {
            $byNumber = (clone $candidates)->where('enrollment_number', $data['registration_number'])->first();

            if ($byNumber !== null) {
                return $byNumber;
            }
        }

        return (clone $candidates)
            ->whereRaw('lower(last_name) = ?', [Str::lower($data['last_name'])])
            ->whereRaw('lower(first_name) = ?', [Str::lower($data['first_names'])])
            ->whereDate('birth_date', $data['birth_date'])
            ->first();
    }

    /**
     * @param  list<array<string, mixed>>  $guardians
     */
    private function syncGuardians(array $guardians): int
    {
        $syncedUserIds = [];
        $keptLinks = [];

        foreach ($guardians as $data) {
            $user = User::query()->where('talenda_guardian_uuid', $data['uuid'])->first()
                ?? $this->findUser($data['account_uuid'], $data['phone'], $data['email']);

            $user = $this->saveUser($user, [
                'name' => $data['full_name'],
                'phone' => $data['phone'],
                'email' => $data['email'],
                'talenda_account_uuid' => $data['account_uuid'],
                'talenda_guardian_uuid' => $data['uuid'],
                'is_active' => true,
            ], 'parent');

            $syncedUserIds[] = $user->id;

            foreach ($data['children'] as $child) {
                $studentId = $this->students[$child['student_uuid']] ?? null;

                if ($studentId === null) {
                    continue;
                }

                // Créé par le modèle pivot, jamais par attach() : tenant_id
                // doit être renseigné (voir BelongsToTenant).
                $link = StudentGuardian::query()->firstOrNew(['student_id' => $studentId, 'user_id' => $user->id]);
                $link->forceFill([
                    'relationship_type' => self::relationship($child['relationship']),
                    'is_primary_contact' => (bool) $child['is_primary_contact'],
                ])->save();

                $keptLinks[] = $link->id;
            }
        }

        // Lien parent-enfant retiré dans Talenda.
        StudentGuardian::query()
            ->whereIn('student_id', $this->students)
            ->whereIn('user_id', User::query()->whereNotNull('talenda_guardian_uuid')->select('id'))
            ->whereKeyNot($keptLinks)
            ->delete();

        // Responsable qui n'a plus d'enfant inscrit dans Talenda.
        User::query()
            ->whereNotNull('talenda_guardian_uuid')
            ->whereKeyNot($syncedUserIds)
            ->whereDoesntHave('teacher')
            ->update(['is_active' => false]);

        return count($syncedUserIds);
    }

    /**
     * Compte déjà relié à ce compte Talenda, ou compte saisi à la main dans
     * Scolia avec le même téléphone ou le même e-mail.
     */
    private function findUser(?string $accountUuid, ?string $phone, ?string $email): ?User
    {
        if ($accountUuid !== null) {
            $linked = User::query()->where('talenda_account_uuid', $accountUuid)->first();

            if ($linked !== null) {
                return $linked;
            }
        }

        $this->tenantUsers ??= User::query()->whereNull('talenda_account_uuid')->whereNull('talenda_guardian_uuid')->get();
        $phone = PhoneNumber::normalize($phone);

        return $this->tenantUsers->first(fn (User $user): bool => ($phone !== null && PhoneNumber::normalize($user->phone) === $phone)
            || ($email !== null && $user->email !== null && Str::lower($user->email) === Str::lower($email)));
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function saveUser(?User $user, array $attributes, string $role): User
    {
        $user ??= new User(['password' => Str::password(40), 'locale' => 'fr']);

        // Ne pas effacer un lien déjà posé par l'autre rôle (un enseignant
        // qui est aussi parent d'élève), ni un e-mail ou un téléphone que
        // Talenda ne connaît pas.
        $attributes = array_filter($attributes, fn ($value, string $key): bool => $value !== null || ! in_array($key, ['talenda_account_uuid', 'talenda_guardian_uuid', 'email', 'phone'], true), ARRAY_FILTER_USE_BOTH);

        // E-mail déjà pris dans l'école par un autre compte : on ne le
        // recopie pas plutôt que de bloquer toute la synchronisation.
        if (filled($attributes['email'] ?? null) && User::query()->when($user->exists, fn ($query) => $query->whereKeyNot($user->id))->where('email', $attributes['email'])->exists()) {
            unset($attributes['email']);
        }

        $user->forceFill($attributes)->save();
        $this->tenantUsers = $this->tenantUsers?->reject(fn (User $candidate): bool => $candidate->is($user));

        if (! $user->hasRole($role)) {
            $user->assignRole($role);
        }

        return $user;
    }

    private static function relationship(string $relationship): string
    {
        return match ($relationship) {
            'father' => 'père',
            'mother' => 'mère',
            'guardian' => 'tuteur',
            default => 'autre',
        };
    }
}
