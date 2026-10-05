<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\MessagingPermissionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['teacher_id', 'can_be_contacted_directly', 'requires_admin_relay'])]
class MessagingPermission extends Model
{
    /** @use HasFactory<MessagingPermissionFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return [
            'can_be_contacted_directly' => 'boolean',
            'requires_admin_relay' => 'boolean',
        ];
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }
}
