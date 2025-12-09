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

    /**
     * Handle Time-In via QR Scan
     */
    public function scan(Request $request)
    {
        // 1. Validation: Expecting 'student_id' to be the String form (e.g., "2023-001")
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
            
            // 2. Find Student by SCHOOL ID String
            $student = Student::where('student_id', $scannedId)->first();

            if (!$student) {
                return response()->json(['status' => 'error', 'message' => 'Student ID not found in database.'], 404);
            }

            // 3. Check for existing participation using the resolved Primary Key ($student->id)
            $existing = Participation::where('student_id', $student->id)
                ->where('event_id', $request->event_id)
                ->lockForUpdate()
                ->first();

            // Scenario: Already In (Time out is null)
            if ($existing && $existing->time_out === null) {
                return response()->json([
                    'status' => 'already_in', 
                    'message' => 'Student is already timed in.'
                ]);
            }

            // Scenario: Already Completed (Time out is set)
            if ($existing && $existing->time_out !== null) {
                // Determine logic: Allow re-entry? Or block? usually we block duplicate entries per event.
                 return response()->json([
                    'status' => 'error', 
                    'message' => 'Student has already completed this event.'
                ], 422);
            }

            // Scenario: New Entry
            Participation::create([
                'student_id' => $student->id, // Use Database PK
                'event_id' => $request->event_id,
                'time_in' => now(),
            ]);

            return response()->json(['status' => 'joined', 'message' => 'Participation recorded!']);
        });
    }

    /**
     * Handle Time-Out via Confirmation
     */
    public function timeOut(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
            'student_id' => 'required' // Expecting String ID (e.g. "2023-001")
        ]);

        $user = $request->user();
        $event = Event::find($request->event_id);
        
        if (!$this->isAuthorized($user, $event)) {
             return response()->json(['status' => 'error', 'message' => 'Unauthorized event manager.'], 403);
        }

        return DB::transaction(function () use ($request) {
            $scannedId = $request->input('student_id'); 
            
            // 1. Find Student by SCHOOL ID String
            $student = Student::where('student_id', $scannedId)->first();
            
            if (!$student) {
                 return response()->json(['status' => 'error', 'message' => 'Student ID required for timeout.'], 422);
            }
            
            // 2. Find Participation using resolved Primary Key ($student->id)
            $participation = Participation::where('student_id', $student->id)
                ->where('event_id', $request->event_id)
                ->whereNull('time_out') // Only find sessions that are still active
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
            'student_id' => 'required' // String ID
        ]);

        $student = Student::where('student_id', $request->student_id)->first();

        if (!$student) {
            return response()->json(['status' => 'not_found']);
        }

        $participation = Participation::where('student_id', $student->id)
            ->where('event_id', $request->event_id)
            ->first();

        if (!$participation) {
            return response()->json(['status' => 'none']); // Ready for Time In
        }

        if ($participation->time_out === null) {
            return response()->json(['status' => 'active']); // Ready for Time Out
        }

        return response()->json(['status' => 'completed']); // Already done
    }
}