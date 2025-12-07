<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Database\Seeders\EventSeeder;
use Database\Seeders\StudentSeeder;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        // 1. Create the Admin (Keep this)
        User::factory()->create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'is_admin' => true, // Assuming you handle admin flag here
        ]);

        // REMOVED: $regularUser creation. 
        // We want the students to generate their own User accounts via the Observer.

        // 2. Create Mitz Ignacio
        // DO NOT pass 'user_id'. The Observer will create the user '23-0613'.
        \App\Models\Student::factory()->create([
            'student_id' => '23-0613',
            'lrn' => '103298100017',
            'name' => 'Mitz Ignacio',
            'course' => 'BSIT',
            'year_lvl' => 3,
            'department' => 'CCSICT',
        ]);

        // 3. Create Shaine Paolo Valdez
        // DO NOT pass 'user_id'. The Observer will create the user '23-0622'.
        \App\Models\Student::factory()->create([
            'student_id' => '23-0622',
            'name' => 'Shaine Paolo Valdez',
            'course' => 'BSIT',
            'year_lvl' => 3,
            'department' => 'CCSICT',
        ]);

        $this->call([
            StudentSeeder::class,
            EventSeeder::class,
            ParticipationSeeder::class,
        ]);
    }
}