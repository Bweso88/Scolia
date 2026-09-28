<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Identité visuelle de l'école consommée par l'app mobile pour le
 * "branding au runtime" (voir docs/PRODUCT_ARCHITECTURE.md §5 et §16).
 */
class TenantResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $settings = $this->settings;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'display_name' => $settings?->display_name ?? $this->name,
            'logo_url' => $settings?->logo_path ? asset('storage/'.$settings->logo_path) : null,
            'cover_image_url' => $settings?->cover_image_path ? asset('storage/'.$settings->cover_image_path) : null,
            'primary_color' => $settings?->primary_color,
            'secondary_color' => $settings?->secondary_color,
            'phone' => $settings?->phone,
            'email' => $settings?->email,
            'address' => $settings?->address,
            'messaging_cutoff_time' => $settings?->messaging_cutoff_time,
        ];
    }
}
