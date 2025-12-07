<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Student;
use App\Models\User;

class StudentSeeder extends Seeder
{
    public function run()
    {
        // Just create students. The Observer will create the Users automatically.
        Student::factory()
            ->count(40)
            ->create(); 
    }
}
