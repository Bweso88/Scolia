<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Lie un parent (existant via `user_id`, ou nouveau via `name` +
 * `email` + `password`) à un élève. Voir
 * App\Filament\Resources\Students\RelationManagers\StudentGuardiansRelationManager
 * pour l'équivalent côté panel web.
 */
class StoreStudentGuardianRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('student.manage');
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'user_id' => [
                'required_without_all:name,email,password',
                Rule::exists('users', 'id')->where('tenant_id', $tenantId),
            ],
            'name' => ['required_without:user_id', 'string', 'max:255'],
            'email' => ['required_without:user_id', 'email', Rule::unique('users', 'email')->where('tenant_id', $tenantId)],
            'password' => ['required_without:user_id', 'string', 'min:8'],
            'relationship_type' => ['required', Rule::in(['mère', 'père', 'tuteur', 'autre'])],
            'is_primary_contact' => ['sometimes', 'boolean'],
        ];
    }
}
