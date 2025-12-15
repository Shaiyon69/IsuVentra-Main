<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Participation;
use Illuminate\Support\Facades\DB;
use App\Models\Student;
use App\Models\Event;

class ParticipationController extends Controller
{

    // Flutter helper func.
    private function isAuthorized($user, $event)
    {
        if (!$event) return false;
        if ($user->is_admin == 1) return true; // Super Admin
        if ($user->is_admin == 2 && $event->managers()->where('user_id', $user->id)->exists()) {
            return true;
        }
        return false;
    }

    public function index(Request $request)
    {
        $query = Participation::with(['student', 'event']);

        if ($request->has('search') && $request->filled('search')) {
            $search = $request->input('search');
            
            $query->where(function($q) use ($search) {
                $q->whereHas('student', function($subQ) use ($search) {
                    $subQ->where('name', 'like', "%{$search}%")
                           ->orWhere('student_id', 'like', "%{$search}%");
                })
                ->orWhereHas('event', function($subQ) use ($search) {
                    $subQ->where('title', 'like', "%{$search}%");
                });
            });
        }

        $query->orderBy('time_in', 'desc');

        $perPage = $request->input('per_page', 15);

        $participations = $query->paginate($perPage)
            ->through(function ($p) {
                return [
                    'id' => $p->id,
                    'student_id' => $p->student_id,
                    'event_id' => $p->event_id,
                    'student_name' => $p->student ? $p->student->name : 'Unknown', 
                    'student_school_id' => $p->student ? $p->student->student_id : 'N/A',
                    'event_name' => $p->event ? $p->event->title : 'Unknown',   
                    'event_end' => $p->event ? $p->event->time_end : null,
                    
                    'time_in' => $p->time_in,
                    'time_out' => $p->time_out,
                ];
            });

        return response()->json($participations);
    }

    public function store(Request $request) 
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'event_id' => 'required|exists:events,id',
            'time_in' => 'required|date',
            'time_out' => 'nullable|date|after:time_in'
        ]);

        $event = Event::find($request->event_id);
        
        if (!$this->isAuthorized($request->user(), $event)) {
             return response()->json(['message' => 'Unauthorized. You are not a manager of this event.'], 403);
        }

        $participation = DB::transaction(function () use ($validated) {
            return Participation::create($validated);
        });

        return response()->json($participation, 201);
    }

    public function destroy(string $id)
    {
        $participation = Participation::find($id);
        if (!$participation) return response()->json(['message' => 'Participation not found'], 404);

        DB::transaction(function () use ($participation) {
            $participation->delete();
        });
        return response()->json(['message' => 'Deleted successfully'], 200);
    }

    public function scan(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
            'student_id' => 'required' 
        ]);

        $user = $request->user();
        $event = Event::find($request->event_id);

        if (!$this->isAuthorized($user, $event)) {
             return response()->json(['status' => 'error', 'message' => 'Unauthorized event manager.'], 403);
        }

        return DB::transaction(function () use ($request) {
            $scannedId = $request->input('student_id'); 
            
            $student = Student::find($scannedId);

            if (!$student) {
                $student = Student::where('student_id', $scannedId)->first();
            }

            if (!$student) {
                return response()->json(['status' => 'error', 'message' => 'Student ID not found in database.'], 404);
            }

            $existing = Participation::where('student_id', $student->id)
                ->where('event_id', $request->event_id)
                ->lockForUpdate()
                ->first();

            if ($existing && $existing->time_out === null) {
                return response()->json([
                    'status' => 'already_in', 
                    'message' => 'Student is already timed in.'
                ], 422); 
            }

            if ($existing && $existing->time_out !== null) {
                 return response()->json([
                    'status' => 'error', 
                    'message' => 'Student has already completed this event.'
                ], 422);
            }

            Participation::create([
                'student_id' => $student->id, // Use Database PK
                'event_id' => $request->event_id,
                'time_in' => now(),
            ]);

            return response()->json(['status' => 'joined', 'message' => 'Participation recorded!']);
        });
    }

    public function timeOut(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
            'student_id' => 'required'
        ]);

        $user = $request->user();
        $event = Event::find($request->event_id);
        
        if (!$this->isAuthorized($user, $event)) {
             return response()->json(['status' => 'error', 'message' => 'Unauthorized event manager.'], 403);
        }

        return DB::transaction(function () use ($request) {
            $scannedId = $request->input('student_id'); 
            
            $student = Student::find($scannedId);
            if (!$student) {
                $student = Student::where('student_id', $scannedId)->first();
            }
            
            if (!$student) {
                 return response()->json(['status' => 'error', 'message' => 'Student ID required for timeout.'], 404);
            }
            
            $participation = Participation::where('student_id', $student->id)
                ->where('event_id', $request->event_id)
                ->whereNull('time_out')
                ->lockForUpdate()
                ->first();

            if (!$participation) {
                return response()->json(['status' => 'not_found', 'message' => 'No active participation found.'], 404);
            }

            $participation->update(['time_out' => now()]);

            return response()->json(['status' => 'timed_out', 'message' => 'Timed out successfully.']);
        });
    }

    public function checkStatus(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
            'student_id' => 'required' 
        ]);

        $student = Student::where('student_id', $request->student_id)->first();

        if (!$student) {
            return response()->json(['status' => 'not_found']);
        }

        $participation = Participation::where('student_id', $student->id)
            ->where('event_id', $request->event_id)
            ->first();

        if (!$participation) {
            return response()->json(['status' => 'none']); 
        }

        if ($participation->time_out === null) {
            return response()->json(['status' => 'active']); 
        }

        return response()->json(['status' => 'completed']); 
    }
}