<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Event;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class EventController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        // Fetch all events, ordered by start time
        $events = Event::orderBy('time_start')->get();

        // Add is_ongoing field based on current time
        $now = Carbon::now();
        $events->transform(function ($event) use ($now) {
            $event->is_ongoing = $now->between($event->time_start, $event->time_end);
            return $event;
        });

        // Return as JSON array for frontend compatibility
        return response()->json($events);
    }


    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'time_start' => 'required|date_format:Y-m-d H:i:s',
            'time_end' => 'required|date_format:Y-m-d H:i:s|after:time_start',
            'location' => 'required|string|max:255',
        ]);

        $event = DB::transaction(function () use ($validated) {
            return Event::create($validated);
        });

        return response()->json([
            'message' => 'Event created successfully',
            'event' => $event
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $event = Event::find($id);
        return response()->json($event);
    }


    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|nullable|string',
            'time_start' => 'sometimes|required|date_format:Y-m-d H:i:s',
            'time_end' => 'sometimes|required|date_format:Y-m-d H:i:s|after:time_start',
            'location' => 'sometimes|required|string|max:255',
        ]);

        $event = Event::find($id);
        if (!$event) {
            return response()->json(['message' => 'Event not found'], 404);
        }

        DB::transaction(function () use ($event, $validated) {
            $event->update($validated);
        });

        return response()->json([
            'message' => 'Event updated successfully',
            'event' => $event
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $event = Event::find($id);
        if (!$event) {
            return response()->json(['message' => 'Event not found'], 404);
        }

        DB::transaction(function () use ($event) {
            $event->delete();
        });

        return response()->json(['message' => 'Event deleted successfully'], 200);
    }

    public function import(Request $request)
    {
        $request->validate([
            'data' => 'required|array',
            'data.*.title' => 'required',
            'data.*.time_start' => 'required|date',
            'data.*.time_end' => 'required|date|after:data.*.time_start',
            'data.*.location' => 'required',
        ]);

        // Transaction already implemented here
        DB::transaction(function () use ($request) {
            foreach ($request->data as $row) {
                Event::create([
                    'title' => $row['title'],
                    'time_start' => date('Y-m-d H:i:s', strtotime($row['time_start'])),
                    'time_end' => date('Y-m-d H:i:s', strtotime($row['time_end'])),
                    'location' => $row['location'],
                    'description' => $row['description'] ?? null,
                ]);
            }
        });

        return response()->json(['message' => 'Events imported successfully!']);
    }
}