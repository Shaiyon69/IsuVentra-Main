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
    
    // 1. ADD THIS: Tell Laravel to include the custom attribute in JSON
    protected $appends = ['is_ongoing'];

    // 2. ADD THIS: The logic to calculate it
    public function getIsOngoingAttribute()
    {
        $now = now();
        // Returns TRUE if now is between start and end time
        return $now->between($this->time_start, $this->time_end);
    }

    protected $casts = [
        'time_start' => 'datetime',
        'time_end' => 'datetime',
    ];
    public function creator() {
        return $this->belongsTo(User::class, 'created_by');
    }

    // The list of sub-admins allowed to manage this event
    public function managers() {
        return $this->belongsToMany(User::class, 'event_managers');
    }

    public function participations()
    {
        return $this->hasMany(Participation::class);
    }
}
