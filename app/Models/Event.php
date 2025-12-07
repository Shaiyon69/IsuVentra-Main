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
        'location',
        'created_by'
    ];

    public function creator() {
        return $this->belongsTo(User::class, 'created_by');
    }

    // The list of sub-admins allowed to manage this event
    public function managers() {
        return $this->belongsToMany(User::class, 'event_managers');
    }
    protected $casts = [
        'time_start' => 'datetime',
        'time_end' => 'datetime',
    ];

    public function participations()
    {
        return $this->hasMany(Participation::class);
    }
}
