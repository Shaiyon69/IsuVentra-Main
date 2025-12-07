<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\StudentController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\ParticipationController;
use App\Http\Controllers\AnalyticsController;
use App\Http\Controllers\Auth\AuthController;
use App\Http\Middleware\AdminCheck;

/*
|--------------------------------------------------------------------------
| PUBLIC / OPEN ROUTES (No Login Required)
|--------------------------------------------------------------------------
*/

// Auth
Route::controller(AuthController::class)->group(function () {
    Route::post('/register', 'register');
    Route::post('/login', 'login');
});

/*
|--------------------------------------------------------------------------
| PROTECTED ROUTES (Login Required)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    // COMMON ROUTES
    Route::name('api.')->group(function () {
        Route::get('students', [StudentController::class, 'index']);
        Route::get('students/{id}', [StudentController::class, 'show']);

        Route::get('events', [EventController::class, 'index']);
        Route::get('events/{id}', [EventController::class, 'show']);

        Route::get('participations', [ParticipationController::class, 'index']);
        Route::get('participations/{id}', [ParticipationController::class, 'show']);
    });
    // User Profile
    //Code requred for Flutter 
    Route::get('user', function (Request $request) {
        $user = $request->user();
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
            $response['year_level'] = $student->year_lvl;
            $response['campus'] = $student->campus;
        }

        return response()->json($response);
    });

    Route::get('/validate-token', function (Request $request) {
        return response()->json(['valid' => true, 'user' => $request->user()]);
    });

    Route::post('/logout', [AuthController::class, 'logout']);

    // QR Code Actions (Students need this)
    Route::controller(ParticipationController::class)->group(function () {
        Route::post('/participations/scan', 'scan');
        Route::post('/participations/out', 'timeOut');
    });


    //ADMIN EXCLUSIVE ROUTES
    Route::middleware([AdminCheck::class])->group(function () {

        // Analytics and Forecasting
        Route::get('/analytics/forecast', [AnalyticsController::class, 'getForecast']);
        Route::get('/analytics/stats', [AnalyticsController::class, 'getDashboardStats']);

        // Lightweight Lists for Modals' Dropdowns
        Route::get('/list/students', [StudentController::class, 'listAll']);
        Route::get('/list/events', [EventController::class, 'listAll']);

        // Manual Participation Entry and Deletion
        Route::controller(ParticipationController::class)->group(function () {
            Route::post('participations', 'store'); // Manual Add (Admin only)
            Route::delete('participations/{id}', 'destroy');
        });

        // Assign Event Managers
        Route::post('/events/{id}/assign', [EventController::class, 'assignManager']);

        // Event Management (CUD + Import)
        Route::controller(EventController::class)->group(function () {
            Route::post('events', 'store');
            Route::post('/events/import', 'import');
            Route::put('events/{id}', 'update');
            Route::delete('events/{id}', 'destroy');
        });

        // Student Management (CUD + Import)
        Route::controller(StudentController::class)->group(function () {
            Route::post('students', 'store');
            Route::post('/students/import', 'import');
            Route::put('students/{id}', 'update');
            Route::delete('students/{id}', 'destroy');
        });

    }); 

});