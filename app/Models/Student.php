<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;
    protected $fillable = [
        'user_id',
        'student_id',
        'lrn',
        'name',
        'course',
        'year_lvl',
        'campus'
    ];
    public function user()
    {
        return $this->belongsTo(User::class); 
    }
    public function participations()
    {
        return $this->hasMany(Participation::class);
    }
}
