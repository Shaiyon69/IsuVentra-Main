<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class EventFactory extends Factory
{
    protected $model = \App\Models\Event::class;

    public function definition()
    {
        // Default year: current year
        $year = null;

        // Default fallbacks
        $start = $this->faker->dateTimeBetween('+1 days', '+10 days');

        // Shorter title base fallback
        $titleBase = $this->faker->words($this->faker->numberBetween(1, 2), true);

        // Description and location
        $description = $this->faker->paragraph();
        $location = $this->faker->city();

        return [
            'title' => $titleBase,
            'time_start' => $start,
            'time_end' => (clone $start)->modify('+2 hours'),
            'description' => $description,
            'location' => $location,
        ];
    }

    /**
     * State to generate event with a specific year in start/end time and title.
     *
     * @param int $year The target year for event.
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function withYear(int $year)
    {
        return $this->state(function (array $attributes) use ($year) {
            $start = $this->faker->dateTimeBetween("first day of January $year", "last day of December $year");
            $titleWordsCount = $this->faker->numberBetween(1, 2);
            $titleBase = $this->faker->words($titleWordsCount, true);
            $title = trim($titleBase) . ' ' . $year;

            return [
                'time_start' => $start,
                'time_end' => (clone $start)->modify('+2 hours'),
                'title' => $title,
            ];
        });
    }
}
