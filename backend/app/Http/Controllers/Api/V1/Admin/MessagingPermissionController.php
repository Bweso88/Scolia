<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Teacher;
use Illuminate\Http\Request;

/**
 * Configuration par l'administration des enseignants joignables
 * directement par les parents (docs/PRODUCT_ARCHITECTURE.md §7 et §15,
 * table messaging_permissions).
 */
class MessagingPermissionController extends Controller
{
    public function update(Request $request, Teacher $teacher)
    {
        abort_if($teacher->tenant_id !== $request->user()->tenant_id, 404);
        abort_unless($request->user()->hasRole(['school_admin', 'direction']), 403);

        $validated = $request->validate([
            'can_be_contacted_directly' => ['required', 'boolean'],
            'requires_admin_relay' => ['sometimes', 'boolean'],
        ]);

        $permission = $teacher->messagingPermission()->updateOrCreate([], $validated);

        return response()->json([
            'teacher_id' => $teacher->id,
            'can_be_contacted_directly' => $permission->can_be_contacted_directly,
            'requires_admin_relay' => $permission->requires_admin_relay,
        ]);
    }
}
