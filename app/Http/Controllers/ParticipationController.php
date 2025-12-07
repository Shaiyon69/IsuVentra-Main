<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Participation;
use Illuminate\Support\Facades\DB;

class ParticipationController extends Controller
{
    // ============================
    // Standard CRUD
    // ============================
    public function index()
    {
        // PAGINATION ADDED: paginate(15) instead of get()
        // 'through' allows transforming the data without losing pagination metadata
        $participations = Participation::with(['student', 'event'])
            ->orderBy('time_in', 'desc')
            ->paginate(15) 
            ->through(function ($p) {
                return [
                    'id' => $p->id,
                    'student_id' => $p->student_id,
                    'event_id' => $p->event_id,
                    'student_name' => $p->student ? $p->student->name : 'Unknown',
                    'event_name' => $p->event ? $p->event->title : 'Unknown',
                    'time_in' => $p->time_in,
                    'time_out' => $p->time_out,
                ];
            });

        return response()->json($participations);
    }

    public function store(Request $request) {
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'event_id' => 'required|exists:events,id',
            'time_in' => 'required|date',
            'time_out' => 'nullable|date|after:time_in'
        ]);

        $participation = DB::transaction(function () use ($validated) {
            return Participation::create($validated);
        });

        return response()->json($participation, 201);
    }

    public function destroy(string $id)
    {
        $participation = Participation::find($id);
        if (!$participation) {
            return response()->json(['message' => 'Participation not found'], 404);
        }

        DB::transaction(function () use ($participation) {
            $participation->delete();
        });

        return response()->json(['message' => 'Deleted successfully'], 200);
    }

    // ============================
    // QR Code Actions
    // ============================
    public function scan(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
        ]);

        return DB::transaction(function () use ($request) {
            $user = $request->user();
            $student = $user->student;

            if (!$student) {
                return response()->json(['status' => 'error', 'message' => 'No student record found.'], 422);
            }

            // Lock for update ensures no double-scans
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
        $request->validate([
            'event_id' => 'required|exists:events,id',
        ]);

        return DB::transaction(function () use ($request) {
            $user = $request->user();
            
            $participation = Participation::where('student_id', $user->student->id)
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

    public function getDashboardStats()
    {
        // 1. Card Counts (Fast aggregate queries)
        $totalStudents = Student::count();
        $totalEvents = Event::count();
        $totalParticipations = Participation::count();

        // 2. Main Chart Data (Group by Event)
        // This gives us the total count per event without loading all rows
        $eventPopularity = DB::table('participations')
            ->join('events', 'participations.event_id', '=', 'events.id')
            ->select('events.title', DB::raw('count(*) as total'))
            ->groupBy('events.title')
            ->orderByDesc('total')
            ->get();

        return response()->json([
            'counts' => [
                'students' => $totalStudents,
                'events' => $totalEvents,
                'participations' => $totalParticipations
            ],
            'chart_data' => $eventPopularity
        ]);
    }
}