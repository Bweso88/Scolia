<?php

use App\Http\Controllers\Api\V1\ChildrenController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Espace parent — /api/v1/children/*
|--------------------------------------------------------------------------
|
| Lecture seule des données des propres enfants du parent connecté
| (docs/PRODUCT_ARCHITECTURE.md §9 et §12). Un membre du personnel peut
| aussi consulter, filtré par la même StudentPolicy que le back-office.
*/
Route::prefix('children')->name('children.')->group(function () {
    Route::get('/', [ChildrenController::class, 'index'])->name('index');
    Route::get('{student}/dashboard', [ChildrenController::class, 'dashboard'])->name('dashboard');
    Route::get('{student}/homeworks', [ChildrenController::class, 'homeworks'])->name('homeworks');
    Route::get('{student}/behavior', [ChildrenController::class, 'behavior'])->name('behavior');
    Route::get('{student}/attendance', [ChildrenController::class, 'attendance'])->name('attendance');
    Route::get('{student}/timetable', [ChildrenController::class, 'timetable'])->name('timetable');
    Route::get('{student}/grades', [ChildrenController::class, 'grades'])->name('grades');
    Route::get('{student}/announcements', [ChildrenController::class, 'announcements'])->name('announcements');
});
