<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\StudentController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\ParticipationController;

use App\Http\Controllers\Auth\AuthController;

Route::get('user', function (Request $request) {
    return $request->user();
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
        Route::get('participations', 'index');
        Route::get('participations/{id}', 'show');
    });
}); 

// Admin-only (Protected APIs)
Route::middleware('auth:sanctum')->group(function () {

    Route::controller(ParticipationController::class)->group(function () {
        Route::post('participations', 'store');
        Route::delete('participations/{id}', 'destroy');
    });


    Route::controller(EventController::class)->group(function () {
        Route::post('events', 'store');
        Route::put('events/{id}', 'update');
        Route::delete('events/{id}', 'destroy');
    });

    Route::controller(StudentController::class)->group(function () {
        Route::post('students', 'store');
        Route::put('students/{id}', 'update');
        Route::delete('students/{id}', 'destroy');
    });

});

//User Routes

Route::controller(AuthController::class)->group(function () {
    Route::post('/register', 'register');
    Route::post('/login', 'login');
});
