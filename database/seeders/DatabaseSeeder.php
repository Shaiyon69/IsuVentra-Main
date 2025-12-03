<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Database\Seeders\EventSeeder;
use Database\Seeders\StudentSeeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run()
    {
        // Create 2 users: one admin and one regular
        $adminUser = \App\Models\User::factory()->admin()->create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
        ]);

        $regularUser = \App\Models\User::factory()->create([
            'name' => 'Regular User',
            'email' => 'user@example.com',
        ]);

        // Create 1 student tied to the regular user
        \App\Models\Student::factory()->create([
            'user_id' => $regularUser->id,
            'student_id' => 'S0001',
            'name' => 'John Doe',
            'course' => 'BSCS',
            'year_lvl' => 3,
            'campus' => 'Main',
        ]);

        $this->call([
            StudentSeeder::class,
            EventSeeder::class,
            ParticipationSeeder::class,
        ]);
    }

}
