<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Conversation;
use App\Models\Teacher;
use App\Models\TeacherAssignment;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * Empêche un parent de contacter directement un enseignant que l'école n'a
 * pas autorisé (docs/PRODUCT_ARCHITECTURE.md §7, table messaging_permissions
 * et §15). Le personnel de l'école (school_admin, direction, teacher,
 * surveillant) n'est pas soumis à cette restriction.
 */
class StoreConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Conversation::class);
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'participant_user_id' => ['required', Rule::exists('users', 'id')->where('tenant_id', $tenantId)],
            'subject' => ['nullable', 'string', 'max:255'],
            'student_id' => ['nullable', Rule::exists('students', 'id')->where('tenant_id', $tenantId)],
            'body' => ['required', 'string'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            if ($this->user()->hasRole(['school_admin', 'direction', 'teacher', 'surveillant'])) {
                return;
            }

            if ($this->user()->tenant?->settings?->isPastMessagingCutoff()) {
                $validator->errors()->add(
                    'body',
                    "La messagerie est fermée pour aujourd'hui (heure limite : {$this->user()->tenant->settings->messaging_cutoff_time}). Réessayez demain."
                );

                return;
            }

            if (! $this->filled('participant_user_id')) {
                return;
            }

            $target = User::find($this->input('participant_user_id'));

            // La direction (school_admin/direction) est toujours joignable,
            // sans restriction de classe.
            if ($target?->hasRole(['school_admin', 'direction'])) {
                return;
            }

            $teacher = Teacher::where('user_id', $this->input('participant_user_id'))->first();

            if (! $teacher) {
                $validator->errors()->add(
                    'participant_user_id',
                    "Un parent ne peut écrire qu'aux enseignants de ses enfants ou à la direction."
                );

                return;
            }

            if (! $teacher->messagingPermission?->can_be_contacted_directly) {
                $validator->errors()->add(
                    'participant_user_id',
                    "Cet enseignant n'est pas joignable directement : passez par l'administration de l'école."
                );

                return;
            }

            $classesDesEnfants = $this->user()->students()->pluck('school_class_id');

            if (! TeacherAssignment::where('teacher_id', $teacher->id)->whereIn('school_class_id', $classesDesEnfants)->exists()) {
                $validator->errors()->add(
                    'participant_user_id',
                    "Cet enseignant n'enseigne pas dans la classe de votre enfant."
                );
            }
        });
    }
}
