<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreGradingPeriodRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('grade.manage');
    }

    public function rules(): array
    {
        return [
            'school_year_id' => ['required', Rule::exists('school_years', 'id')->where('tenant_id', $this->user()->tenant_id)],
            'label' => ['required', 'string', 'max:100'],
        ];
    }
}
