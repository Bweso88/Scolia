<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\AuditLogFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['actor_type', 'actor_id', 'action', 'subject_type', 'subject_id', 'ip_address', 'user_agent', 'meta'])]
class AuditLog extends Model
{
    /** @use HasFactory<AuditLogFactory> */
    use BelongsToTenant, HasFactory;

    const UPDATED_AT = null;

    protected function casts(): array
    {
        return ['meta' => 'array'];
    }
}
