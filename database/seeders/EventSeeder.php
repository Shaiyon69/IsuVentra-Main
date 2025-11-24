<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Event;

class EventSeeder extends Seeder
{
    public function run()
    {
        // Generate 5 event types, each with events from 2020 to 2025
        for ($eventType = 1; $eventType <= 5; $eventType++) {
            for ($year = 2020; $year <= 2025; $year++) {
                Event::factory()
                    ->withYearAndTitle($year, "Event $eventType")
                    ->create();
            }
        }
    }
}
