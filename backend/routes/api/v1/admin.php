<?php

use App\Http\Controllers\Api\V1\Admin\HomeworkController;
use App\Http\Controllers\Api\V1\Admin\StudentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Back-office école — /api/v1/admin/*
|--------------------------------------------------------------------------
|
| Routes protégées par policies Eloquent (permissions spatie + appartenance
| au tenant, voir docs/PRODUCT_ARCHITECTURE.md §15). Ce fichier ne contient
| pour l'instant que la tranche verticale de référence (élèves, devoirs) ;
| les autres domaines du schéma (§7) suivent le même patron.
*/
Route::prefix('admin')->name('admin.')->group(function () {
    Route::apiResource('students', StudentController::class);
    Route::apiResource('homeworks', HomeworkController::class);
});
