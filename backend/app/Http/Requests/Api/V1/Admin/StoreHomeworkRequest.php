<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Homework;
use App\Models\Teacher;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreHomeworkRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Homework::class);
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'school_class_id' => ['required', Rule::exists('school_classes', 'id')->where('tenant_id', $tenantId)],
            'subject_id' => ['required', Rule::exists('subjects', 'id')->where('tenant_id', $tenantId)],
            'teacher_id' => [
                'nullable',
                Rule::exists('teachers', 'id')->where('tenant_id', $tenantId),
            ],
            'lesson_id' => ['nullable', Rule::exists('lessons', 'id')->where('tenant_id', $tenantId)],
            'title' => ['required', 'string', 'max:255'],
            'instructions' => ['nullable', 'string'],
            'due_date' => ['required', 'date', 'after_or_equal:today'],
        ];
    }

    /**
     * Un enseignant publie toujours en son propre nom ; seule
     * l'administration peut publier un devoir pour un autre enseignant.
     */
    protected function passedValidation(): void
    {
        if (! $this->filled('teacher_id')) {
            $teacher = Teacher::where('user_id', $this->user()->id)->first();

            $this->merge(['teacher_id' => $teacher?->id]);
        }
    }
}
