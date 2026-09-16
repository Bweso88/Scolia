<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationPreferenceController extends Controller
{
    private const CATEGORIES = ['devoir', 'absence', 'message', 'annonce', 'bulletin', 'reunion'];

    public function index(Request $request)
    {
        $preferences = $request->user()->notificationPreferences()->get(['category', 'channel', 'is_enabled']);

        return response()->json(['data' => $preferences]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'preferences' => ['required', 'array', 'min:1'],
            'preferences.*.category' => ['required', Rule::in(self::CATEGORIES)],
            'preferences.*.channel' => ['required', Rule::in(['push', 'email'])],
            'preferences.*.is_enabled' => ['required', 'boolean'],
        ]);

        foreach ($validated['preferences'] as $preference) {
            $request->user()->notificationPreferences()->updateOrCreate(
                ['category' => $preference['category'], 'channel' => $preference['channel']],
                ['is_enabled' => $preference['is_enabled']]
            );
        }

        return response()->json(['data' => $request->user()->notificationPreferences()->get(['category', 'channel', 'is_enabled'])]);
    }
}
