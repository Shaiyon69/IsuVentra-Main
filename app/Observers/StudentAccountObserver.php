<?php

namespace App\Observers;

use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class StudentAccountObserver
{
    /**
     * Handle the Student "created" event.
     */
    public function created(Student $student): void
    {
        if ($student->user_id) {
            return;
        }

        $plainPassword = $student->lrn ?? 'default12345';

        $user = User::create([
            'name'     => $student->name,
            'email'    => $student->student_id, 
            'password' => Hash::make($plainPassword),
            'is_admin' => false,
        ]);

        $student->user_id = $user->id;
        $student->saveQuietly(); 
    }
}