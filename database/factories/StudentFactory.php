<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class StudentFactory extends Factory
{
    protected $model = \App\Models\Student::class;

    public function definition()
    {
        
        return [
            'user_id' => null, 
            'student_id' => $this->faker->unique()->numerify('##-####'),
            'lrn' => $this->faker->numerify('############'), // 12 digits
            'name' => $this->faker->name(),
            'course' => "Test Course",
            'year_lvl' => $this->faker->numberBetween(1, 4),
            'department' => "Test Department",
        ];
    }
}
