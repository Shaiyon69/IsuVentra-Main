<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\StudentController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\ParticipationController;

use App\Http\Controllers\Auth\AuthController;
use App\Http\Middleware\AdminCheck;

Route::get('user', function (Request $request) {
    $user = $request->user();
    // Load student relation if exists
    $user->loadMissing('student');

    $response = [
        'id' => $user->id,
        'name' => $user->name,
        'email' => $user->email,
        'is_admin' => $user->is_admin,
    ];

    if ($user->student) {
        $student = $user->student;
        $response['student_id'] = $student->student_id;
        $response['course'] = $student->course;
        // normalize backend field 'year_lvl' to 'year_level' expected by the mobile app
        $response['year_level'] = $student->year_lvl;
        $response['campus'] = $student->campus;
    }

    return response()->json($response);
})->middleware('auth:sanctum');

// API Routes

// Fetch only (Open APIs)
Route::name('api.')->group(function () {

    Route::controller(StudentController::class)->group(function () {
        Route::get('students', 'index');
        Route::get('students/{id}', 'show');
    });

    Route::controller(EventController::class)->group(function () {
        Route::get('events', 'index');
        Route::get('events/{id}', 'show');
    });

    Route::controller(ParticipationController::class)->group(function () {
        Route::get('participation', 'index');
        Route::get('participation/{id}', 'show');
        Route::get('participation/stats', 'getParticipationStats')->middleware([AdminCheck::class]);
    });
});

// Authorized-only (Protected APIs)
Route::middleware('auth:sanctum')->group(function () {

    //Students can only attend (POST) participations
    Route::controller(ParticipationController::class)->group(function () {
        Route::post('participations', 'store');
        Route::delete('participations/{id}', 'destroy')->middleware([AdminCheck::class]);
    });

    Route::controller(ParticipationController::class)->group(function () {
        Route::post('/participations/scan', 'scan');
        Route::post('/participations/out', 'timeOut');
    });


    Route::controller(EventController::class)->group(function () {
        Route::post('events', 'store');
        Route::put('events/{id}', 'update');
        Route::delete('events/{id}', 'destroy');
    })->middleware([AdminCheck::class]);

    Route::controller(StudentController::class)->group(function () {
        Route::post('students', 'store');
        Route::put('students/{id}', 'update');
        Route::delete('students/{id}', 'destroy');
    })->middleware([AdminCheck::class]);

});

//User Routes

Route::controller(AuthController::class)->group(function () {
    Route::post('/register', 'register');
    Route::post('/login', 'login');
    Route::post('/logout', 'logout')->middleware('auth:sanctum');
});

// routes/api.php
Route::middleware('auth:sanctum')->get('/validate-token', function (Request $request) {
    return response()->json(['valid' => true, 'user' => $request->user()]);
});

