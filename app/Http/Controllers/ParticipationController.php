<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Participation;

class ParticipationController extends Controller
{
    // ============================
    // Standard CRUD / Scan / Timeout
    // ============================
    public function index()
    {
        $participations = Participation::with(['student', 'event'])
            ->orderBy('time_in', 'desc')
            ->get()
            ->map(function ($p) {
                return [
                    'id' => $p->id,
                    'student_id' => $p->student_id,
                    'event_id' => $p->event_id,
                    'student_name' => $p->student->name,
                    'event_name' => $p->event->title,
                    'time_in' => $p->time_in,
                    'time_out' => $p->time_out,
                ];
            });

        return response()->json($participations);
    }

    public function show(string $id)
    {
        $participation = Participation::find($id);
        return response()->json($participation);
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

    public function scan(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
        ]);

        $user = $request->user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'status' => 'error',
                'message' => 'No student record linked to this user.'
            ], 422);
        }

        $participation = Participation::where('student_id', $student->id)
            ->where('event_id', $request->event_id)
            ->first();

        if ($participation) {
            return response()->json([
                'status' => 'already_in',
                'message' => 'You are already participating in this event.'
            ]);
        }

        Participation::create([
            'student_id' => $student->id,
            'event_id' => $request->event_id,
            'time_in' => now(),
        ]);

        return response()->json([
            'status' => 'joined',
            'message' => 'Participation recorded!'
        ]);
    }

    public function timeOut(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
        ]);

        $user = $request->user();
        $eventId = $request->event_id;

        $participation = Participation::where('student_id', $user->id)
            ->where('event_id', $eventId)
            ->first();

        if (!$participation) {
            return response()->json([
                'status' => 'not_found',
                'message' => 'You are not participating in this event.'
            ], 404);
        }

        $participation->update([
            'time_out' => now(),
        ]);

        return response()->json([
            'status' => 'timed_out',
            'message' => 'You have timed out of the event.'
        ]);
    }

    // ====================================
    //  FORECAST METHODS (PER YEAR)
    // ====================================
    private function calculateMovingAverage($data, $window = 3)
    {
        $result = [];
        $count = count($data);
        
        for ($i = 0; $i < $count; $i++) {
            // Need at least 'window' data points to calculate average
            if ($i < $window - 1) {
                $result[] = null; // not enough data for full window
                continue;
            }
            
            // Get the slice of data for this window
            $slice = array_slice($data, $i - $window + 1, $window);
            $result[] = array_sum($slice) / $window;
        }
        
        return $result;
    }

    private function calculateExponentialSmoothing($data, $alpha = 0.3)
    {
        if (empty($data)) {
            return [];
        }

        $result = [];
        $result[0] = $data[0];

        for ($i = 1; $i < count($data); $i++) {
            $result[$i] = $alpha * $data[$i] + (1 - $alpha) * $result[$i - 1];
        }

        return $result;
    }

    /**
     * Generate forecast values for future periods
     * Uses trend from smoothed data
     */
    private function generateForecasts($smoothedData, $horizon = 3)
    {
        if (empty($smoothedData) || count($smoothedData) < 2) {
            return array_fill(0, $horizon, null);
        }

        // Calculate trend from last few smoothed values
        $lastValue = end($smoothedData);
        $secondLastValue = $smoothedData[count($smoothedData) - 2];
        $trend = $lastValue - $secondLastValue;

        // Generate forecasts
        $forecasts = [];
        for ($i = 1; $i <= $horizon; $i++) {
            $forecast = $lastValue + ($trend * $i);
            // Ensure forecast is not negative
            $forecasts[] = max(0, round($forecast, 2));
        }

        return $forecasts;
    }

    // ====================================
    //  FORECAST ENDPOINT (PER EVENT)
    // ====================================
    public function getParticipationForecastPerYear()
    {
        $participations = Participation::with('event')->get();

        if ($participations->isEmpty()) {
            return response()->json([
                'events' => []
            ]);
        }

        // Group by event name, then by year
        $groupedByEvent = [];
        foreach ($participations as $p) {
            if ($p->time_in && $p->event) {
                $eventName = $p->event->title;
                $year = $p->time_in->format('Y');

                if (!isset($groupedByEvent[$eventName])) {
                    $groupedByEvent[$eventName] = [];
                }
                if (!isset($groupedByEvent[$eventName][$year])) {
                    $groupedByEvent[$eventName][$year] = 0;
                }
                $groupedByEvent[$eventName][$year]++;
            }
        }

        $eventsForecast = [];
        foreach ($groupedByEvent as $eventName => $yearlyData) {
            // Sort years chronologically
            ksort($yearlyData);

            $years = array_keys($yearlyData);
            $actualCounts = array_values($yearlyData);

            // Check if we have enough data points for forecasting
            if (count($years) < 2) {
                $eventsForecast[$eventName] = [
                    'message' => 'Not enough participation data for forecasting this event. At least 2 years of historical data are required.',
                    'available_years' => count($years),
                    'years' => $years,
                    'actual' => $actualCounts,
                    'moving_average' => [],
                    'exponential_smoothing' => [],
                    'forecast_years' => [],
                    'forecast_exponential' => [],
                    'forecast_moving_average' => []
                ];
                continue;
            }

            // Calculate smoothing methods
            $movingAvg = $this->calculateMovingAverage($actualCounts, 3);
            $expSmooth = $this->calculateExponentialSmoothing($actualCounts, 0.3);

            // Generate forecasts for next 3 years using exponential smoothing
            $forecastsExp = $this->generateForecasts($expSmooth, 3);

            // Generate forecasts for next 3 years using moving average (use non-null values)
            $nonNullMoving = array_values(array_filter($movingAvg, fn($v) => $v !== null));
            $forecastsMoving = $this->generateForecasts($nonNullMoving, 3);

            $lastYear = (int) end($years);
            $forecastYears = [
                (string) ($lastYear + 1),
                (string) ($lastYear + 2),
                (string) ($lastYear + 3)
            ];

            $eventsForecast[$eventName] = [
                'years' => $years,
                'actual' => $actualCounts,
                'moving_average' => $movingAvg,
                'exponential_smoothing' => $expSmooth,
                'forecast_years' => $forecastYears,
                'forecast_exponential' => $forecastsExp,
                'forecast_moving_average' => $forecastsMoving
            ];
        }

        return response()->json([
            'events' => $eventsForecast
        ]);
    }
}
