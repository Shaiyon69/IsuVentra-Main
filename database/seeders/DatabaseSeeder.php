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
        // Pregenerate admin acc
        User::factory()->create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'is_admin' => true, 
        ]);


        // Create Mitz Ignacio
        \App\Models\Student::factory()->create([
            'student_id' => '23-0613',
            'lrn' => '103298100017',
            'name' => 'Mitz Ignacio',
            'course' => 'BSIT',
            'year_lvl' => 3,
            'department' => 'CCSICT',
        ]);

        // 3. Create Shaine Paolo Valdez
        \App\Models\Student::factory()->create([
            'student_id' => '23-0622',
            'lrn' => '103298100017',
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