<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SubscriptionModuleFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['module_key', 'is_enabled'])]
class SubscriptionModule extends Model
{
    /** @use HasFactory<SubscriptionModuleFactory> */
    use BelongsToTenant, HasFactory;

    protected function casts(): array
    {
        return ['is_enabled' => 'boolean'];
    }
}
