<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = [
        'student_id',
        'name',
        'course',
        'year_lvl',
        'campus'
    ];

    public function participations()
    {
        return $this->hasMany(Participation::class);
    }
}
