<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\Participation;
use App\Models\Student;
use App\Models\Event;

class ParticipationFactory extends Factory
{
    protected $model = Participation::class;

    public function definition()
    {
        $student = Student::inRandomOrder()->first() ?? Student::factory()->create();
        $event = Event::inRandomOrder()->first() ?? Event::factory()->create();

        // Generate time_in between the event's time_start and time_end to match the event's year
        $timeIn = $this->faker->dateTimeBetween($event->time_start, $event->time_end);

        // time_out is always set, after time_in, up to event's time_end or a bit after
        $timeOut = $this->faker->dateTimeBetween($timeIn, (clone $event->time_end)->modify('+1 hour'));

        return [
            'student_id' => $student->id,
            'event_id' => $event->id,
            'time_in' => $timeIn,
            'time_out' => $timeOut,
        ];
    }
}
