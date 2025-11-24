<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use HasFactory;
    protected $fillable = [
        'title',
        'time_start',
        'time_end',
        'description',
        'location'
    ];

    protected $casts = [
        'time_start' => 'datetime',
        'time_end' => 'datetime',
    ];

    public function participations()
    {
        return $this->hasMany(Participation::class);
    }
}
