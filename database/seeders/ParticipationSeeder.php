<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Database\Factories\ParticipationFactory;

class ParticipationSeeder extends Seeder
{
    public function run()
    {
        // Create 100 participations with varied dates for statistics
        \App\Models\Participation::factory()->count(1000)->create();
    }
}
