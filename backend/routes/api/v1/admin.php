<?php

use App\Http\Controllers\Api\V1\Admin\AnnouncementController;
use App\Http\Controllers\Api\V1\Admin\AttendanceRecordController;
use App\Http\Controllers\Api\V1\Admin\BehaviorObservationController;
use App\Http\Controllers\Api\V1\Admin\ConversationController;
use App\Http\Controllers\Api\V1\Admin\DocumentController;
use App\Http\Controllers\Api\V1\Admin\GradeController;
use App\Http\Controllers\Api\V1\Admin\GradingPeriodController;
use App\Http\Controllers\Api\V1\Admin\HomeworkController;
use App\Http\Controllers\Api\V1\Admin\MessageController;
use App\Http\Controllers\Api\V1\Admin\MessagingPermissionController;
use App\Http\Controllers\Api\V1\Admin\StudentController;
use App\Http\Controllers\Api\V1\Admin\TimetableSlotController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Back-office école — /api/v1/admin/*
|--------------------------------------------------------------------------
|
| Routes protégées par policies Eloquent (permissions spatie + appartenance
| au tenant, voir docs/PRODUCT_ARCHITECTURE.md §15). Chaque domaine suit le
| même patron que la tranche de référence (élèves, devoirs) : policy,
| form requests, resource, tenant scoping automatique.
*/
Route::prefix('admin')->name('admin.')->group(function () {
    Route::apiResource('students', StudentController::class);
    Route::apiResource('homeworks', HomeworkController::class);

    Route::apiResource('behavior-observations', BehaviorObservationController::class)
        ->only(['index', 'store', 'show', 'destroy']);

    Route::apiResource('attendance-records', AttendanceRecordController::class)
        ->only(['index', 'store', 'show']);
    Route::post('attendance-records/{attendance_record}/justify', [AttendanceRecordController::class, 'justify'])
        ->name('attendance-records.justify');
    Route::patch('attendance-records/{attendance_record}/justification', [AttendanceRecordController::class, 'reviewJustification'])
        ->name('attendance-records.review-justification');

    Route::apiResource('conversations', ConversationController::class)
        ->only(['index', 'store', 'show']);
    Route::apiResource('conversations.messages', MessageController::class)
        ->only(['index', 'store'])
        ->shallow();

    Route::apiResource('announcements', AnnouncementController::class)
        ->only(['index', 'store', 'show']);

    Route::apiResource('timetable-slots', TimetableSlotController::class)
        ->except(['create', 'edit']);

    Route::patch('teachers/{teacher}/messaging-permission', [MessagingPermissionController::class, 'update'])
        ->name('teachers.messaging-permission.update');

    Route::apiResource('documents', DocumentController::class)
        ->only(['index', 'store', 'show', 'destroy']);

    Route::apiResource('grading-periods', GradingPeriodController::class)
        ->only(['index', 'store']);
    Route::apiResource('grades', GradeController::class)
        ->only(['index', 'store', 'update']);
});
