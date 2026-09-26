<?php

use App\Http\Controllers\Api\V1\Admin\DocumentController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\DeviceTokenController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\NotificationPreferenceController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API v1
|--------------------------------------------------------------------------
|
| Le tenant n'apparaît jamais dans l'URL : il est résolu uniquement depuis
| l'utilisateur authentifié par le middleware `resolve.tenant`
| (voir docs/PRODUCT_ARCHITECTURE.md §9).
|
*/
Route::prefix('v1')->name('api.v1.')->group(function () {
    Route::post('auth/login', [AuthController::class, 'login'])->name('auth.login');

    // Route signée sans authentification : la signature, générée après
    // vérification de la policy dans DocumentController::show, fait foi.
    Route::get('admin/documents/{document}/stream', [DocumentController::class, 'stream'])
        ->middleware('signed')
        ->name('admin.documents.stream');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/select-context', [AuthController::class, 'selectContext'])->name('auth.select-context');
        Route::post('auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
    });

    Route::middleware(['auth:sanctum', 'resolve.tenant'])->group(function () {
        Route::get('me', MeController::class)->name('me');

        Route::post('devices', [DeviceTokenController::class, 'store'])->name('devices.store');
        Route::delete('devices/{fcmToken}', [DeviceTokenController::class, 'destroy'])->name('devices.destroy');

        Route::get('notification-preferences', [NotificationPreferenceController::class, 'index'])->name('notification-preferences.index');
        Route::patch('notification-preferences', [NotificationPreferenceController::class, 'update'])->name('notification-preferences.update');

        Route::get('notifications', [NotificationController::class, 'index'])->name('notifications.index');
        Route::patch('notifications/read-all', [NotificationController::class, 'markAllRead'])->name('notifications.read-all');
        Route::patch('notifications/{notification}/read', [NotificationController::class, 'markRead'])->name('notifications.read');

        require __DIR__.'/api/v1/children.php';
        require __DIR__.'/api/v1/admin.php';
    });
});
