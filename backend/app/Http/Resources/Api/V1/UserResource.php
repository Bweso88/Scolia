<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'roles' => $this->whenLoaded('roles', fn () => $this->roles->pluck('name')),
            'tenant' => new TenantResource($this->whenLoaded('tenant')),
            // Classes assignées, pour un enseignant : évite à l'app mobile
            // un aller-retour supplémentaire pour savoir quelle(s) classe(s)
            // filtrer sur /admin/students et /admin/homeworks.
            'classes' => $this->whenLoaded('teacher', fn () => $this->teacher
                ? $this->teacher->schoolClasses->map(fn ($c) => ['id' => $c->id, 'name' => $c->name])
                : []),
        ];
    }
}
