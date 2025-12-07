<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Participation;
use Illuminate\Support\Facades\DB;
use App\Models\Student;
use App\Models\Event;

class ParticipationController extends Controller
{
    // --- HELPER: Permission Check ---
    private function isAuthorized($user, $event)
    {
        if (!$event) return false;
        if ($user->is_admin === 1) return true; // Super Admin
        if ($user->is_admin === 2 && $event->managers()->where('user_id', $user->id)->exists()) {
            return true;
        }
        return false;
    }

    public function index(Request $request)
    {
        $query = Participation::with(['student', 'event']);

        // 1. Handle Search (Relational)
        if ($request->has('search') && $request->filled('search')) {
            $search = $request->input('search');
            
            // Search inside related Student (name/ID) OR related Event (title)
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

        // 2. Sorting
        $query->orderBy('time_in', 'desc');

        // 3. Dynamic Pagination
        $perPage = $request->input('per_page', 15);

        $participations = $query->paginate($perPage)
            ->through(function ($p) {
                return [
                    'id' => $p->id,
                    'student_id' => $p->student_id,
                    'event_id' => $p->event_id,
                    'student_name' => $p->student ? $p->student->name : 'Unknown', // Flattened for table
                    'student_school_id' => $p->student ? $p->student->student_id : 'N/A',
                    'event_name' => $p->event ? $p->event->title : 'Unknown', // Flattened for table
                    'time_in' => $p->time_in,
                    'time_out' => $p->time_out,
                ];
            });

        return response()->json($participations);
    }

    // --- MANUAL ENTRY (Admin/Manager Only) ---
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

    // --- QR ACTIONS ---
    public function scan(Request $request)
    {
        $request->validate(['event_id' => 'required|exists:events,id']);

        $user = $request->user();
        $event = Event::find($request->event_id);

        if (!$this->isAuthorized($user, $event)) {
             return response()->json(['status' => 'error', 'message' => 'Unauthorized event manager.'], 403);
        }

        return DB::transaction(function () use ($request, $user) {
            $studentId = $request->input('student_id'); 
            
            if ($studentId) {
                $student = Student::find($studentId); 
            } else {
                $student = $user->student;
            }

            if (!$student) {
                return response()->json(['status' => 'error', 'message' => 'Student not found.'], 422);
            }

            $existing = Participation::where('student_id', $student->id)
                ->where('event_id', $request->event_id)
                ->lockForUpdate()
                ->first();

            if ($existing) {
                return response()->json(['status' => 'already_in', 'message' => 'Already participating.']);
            }

            Participation::create([
                'student_id' => $student->id,
                'event_id' => $request->event_id,
                'time_in' => now(),
            ]);

            return response()->json(['status' => 'joined', 'message' => 'Participation recorded!']);
        });
    }

    public function timeOut(Request $request)
    {
        $request->validate(['event_id' => 'required|exists:events,id']);

        $user = $request->user();
        $event = Event::find($request->event_id);
        
        if (!$this->isAuthorized($user, $event)) {
             return response()->json(['status' => 'error', 'message' => 'Unauthorized event manager.'], 403);
        }

        return DB::transaction(function () use ($request) {
            $studentId = request()->input('student_id'); 
            
            if (!$studentId) {
                 return response()->json(['status' => 'error', 'message' => 'Student ID required for timeout.'], 422);
            }
            
            $participation = Participation::where('student_id', $studentId)
                ->where('event_id', $request->event_id)
                ->lockForUpdate()
                ->first();

            if (!$participation) {
                return response()->json(['status' => 'not_found', 'message' => 'Not participating.'], 404);
            }

            $participation->update(['time_out' => now()]);

            return response()->json(['status' => 'timed_out', 'message' => 'Timed out successfully.']);
        });
    }
}