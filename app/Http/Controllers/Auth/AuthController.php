<?php

namespace App\Http\Controllers\Auth;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use App\Models\User;
use Laravel\Sanctum\PersonalAccessToken;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        // Standard registration still enforces email format for admins/regular users
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = DB::transaction(function () use ($validated) {
            return User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
            ]);
        });

        return response()->json([
            'message' => 'User registered successfully',
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        // 1. Validation: Just ensure strings are present
        $validated = $request->validate([
            'email' => 'required|string', 
            'password' => 'required|string',
        ]);

        // 2. Direct Lookup (No modification)
        // This will find "admin@gmail.com" OR "23-0001" exactly as typed.
        $user = User::where('email', $validated['email'])->first();

        // 3. Verify Password
        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // 4. Generate Token
        $token = $user->createToken('auth_token')->plainTextToken;

        // 5. CRITICAL: Load the student relationship
        // This ensures frontend gets auth.user.student.student_id
        $user->load('student');

        return response()->json([
            'message' => 'Login successful as '. $user->name,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user, // Return the full object with relationship loaded
        ]);
    }

    public function logout(Request $request){
        $user = $request->user();
        $user->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully.'
        ]);
    }
    
    public function logoutAllUsers(Request $request)
    {
        $user = $request->user();

        if (!$user->is_admin) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 403);
        }

        DB::transaction(function () {
            PersonalAccessToken::truncate();
        });

        return response()->json([
            'message' => 'All users have been logged out successfully.'
        ]);
    }
}