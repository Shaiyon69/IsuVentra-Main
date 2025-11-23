<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Event;

class EventSeeder extends Seeder
{
    public function run()
    {
        $currentYear = date('Y');
        $yearsBack = 5;
        $eventsPerYear = 2;

        for ($year = $currentYear; $year >= $currentYear - $yearsBack; $year--) {
            Event::factory()
                ->count($eventsPerYear)
                ->withYear($year)
                ->create();
        }
    }
}
