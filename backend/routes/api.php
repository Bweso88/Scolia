<?php

use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\MeController;
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

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/select-context', [AuthController::class, 'selectContext'])->name('auth.select-context');
        Route::post('auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
    });

    Route::middleware(['auth:sanctum', 'resolve.tenant'])->group(function () {
        Route::get('me', MeController::class)->name('me');

        require __DIR__.'/api/v1/admin.php';
    });
});
