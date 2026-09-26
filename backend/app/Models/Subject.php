<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SubjectFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name'])]
class Subject extends Model
{
    /** @use HasFactory<SubjectFactory> */
    use BelongsToTenant, HasFactory;
}
