<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Participation;

class ParticipationController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $participations = Participation::all();
        return response()->json($participations);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $participation = Participation::find($id);
        return response()->json($participation);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|integer|exists:students,id',
            'event_id' => 'required|integer|exists:events,id',
            'time_in' => 'required|date_format:Y-m-d H:i:s',
            'time_out' => 'nullable|date_format:Y-m-d H:i:s|after:time_in',
        ]);
    }

    public function delete(string $id)
    {
        $participation = Participation::find($id);
        if (!$participation) {
            return response()->json(['message' => 'Participation not found'], 404);
        }
        $participation->delete();
        return response()->json(['message' => 'Participation deleted successfully'], 200);
    }

    
}
