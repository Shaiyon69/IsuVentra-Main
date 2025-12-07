<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Student;
use Illuminate\Support\Facades\DB;

class StudentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Student::query();

        // 1. Handle Search
        if ($request->has('search') && $request->filled('search')) {
            $search = $request->input('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('student_id', 'like', "%{$search}%")
                  ->orWhere('lrn', 'like', "%{$search}%")
                  ->orWhere('course', 'like', "%{$search}%");
            });
        }

        // 2. Sort
        $query->orderBy('created_at', 'desc');

        // 3. Dynamic Pagination
        $perPage = $request->input('per_page', 15);
        $students = $query->paginate($perPage); 
        
        return response()->json($students);
    }

    public function listAll()
    {
        // Only fetch ID, Name, and Student ID. Don't fetch created_at, etc.
        $students = Student::select('id', 'name', 'student_id')
            ->orderBy('name')
            ->get();
            
        return response()->json($students);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|string|max:20|unique:students,student_id',
            'lrn'        => 'required|digits:12|unique:students,lrn', 
            'name'       => 'required|string|max:255',
            'course'     => 'required|string|max:100',
            'year_lvl'   => 'required|integer|min:1|max:10',
            'department' => 'required|string|max:100',
        ]);

        $student = DB::transaction(function () use ($validated) {
            return Student::create($validated);
        });

        return response()->json([
            'message' => 'Student created successfully',
            'student' => $student
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $student = Student::where('student_id', $id)->first();
        if (!$student) {
            return response()->json(['message' => 'Student not found'], 404);
        }
        return response()->json($student);
    }


    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'student_id' => 'sometimes|required|string|max:20|unique:students,student_id,' . $id,
            'lrn'        => 'sometimes|required|digits:12|unique:students,lrn,' . $id, 
            'name'       => 'sometimes|required|string|max:255',
            'course'     => 'sometimes|required|string|max:100',
            'year_lvl'   => 'sometimes|required|integer|min:1|max:10',
            'department' => 'sometimes|required|string|max:100',
        ]);

        $student = Student::find($id);
        if (!$student) {
            return response()->json(['message' => 'Student not found'], 404);
        }

        DB::transaction(function () use ($student, $validated) {
            $student->update($validated);
        });

        return response()->json([
            'message' => 'Student updated successfully',
            'student' => $student
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $student = Student::find($id);
        if (!$student) {
            return response()->json(['message' => 'Student not found'], 404);
        }

        DB::transaction(function () use ($student) {
            $student->delete();
        });

        return response()->json(['message' => 'Student deleted successfully'], 200);
    }

    /**
     * Fetch student by student_id.
     */
    public function showByStudentId(string $studentId)
    {
        $student = Student::where('student_id', $studentId)->first();
        if (!$student) {
            return response()->json(['message' => 'Student not found'], 404);
        }
        return response()->json($student);
    }

    public function import(Request $request)
    {
        $request->validate([
            'data' => 'required|array',
            'data.*.student_id' => 'required|distinct|unique:students,student_id',
            'data.*.lrn'        => 'required|digits:12|distinct|unique:students,lrn',
            'data.*.name'       => 'required',
            'data.*.course'     => 'required',
            'data.*.year_lvl'   => 'required|integer',
            'data.*.department' => 'required',
        ]);

        DB::transaction(function () use ($request) {
            foreach ($request->data as $row) {
                Student::create([
                    'student_id' => $row['student_id'],
                    'lrn'        => $row['lrn'], 
                    'name'       => $row['name'],
                    'course'     => $row['course'],
                    'year_lvl'   => $row['year_lvl'],
                    'department' => $row['department'],
                ]);
            }
        });

        return response()->json(['message' => 'Students imported successfully!']);
    }
}