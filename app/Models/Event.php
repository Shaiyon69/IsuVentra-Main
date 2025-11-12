<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    protected $fillable = [
        'title',
        'time_start',
        'time_end',
        'description',
        'location'
    ];

    public function participations()
    {
        return $this->hasMany(Participation::class);
    }
}
