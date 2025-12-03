<?php

namespace App\Providers;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;
use App\Models\Event;
use App\Models\Student;
use App\Models\Participation;
use App\Models\User;
use App\Observers\AuditObserver;
use App\Observers\StudentAccountObserver;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Event::observe(AuditObserver::class);
        Student::observe(AuditObserver::class);
        Participation::observe(AuditObserver::class);
        User::observe(AuditObserver::class);

        DB::listen(function ($query) {
            Log::channel('queries')->info("Query executed in {$query->time} ms: {$query->sql}", [
                'bindings' => $query->bindings,
                'connection' => $query->connectionName,
            ]);
        });

        Student::observe(StudentAccountObserver::class);
    }
}
