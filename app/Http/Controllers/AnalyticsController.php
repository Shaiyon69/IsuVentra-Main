<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Carbon\Carbon;
use App\Models\Participation;
use App\Models\Event;
use App\Models\Student;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function getForecast()
    {
        //Fetch Data
        $participations = Participation::with('event')->get();

        if ($participations->isEmpty()) {
            return response()->json(['events' => []]);
        }

        //Data Grouping
        $groupedByEvent = [];
        foreach ($participations as $p) {
            if ($p->time_in && $p->event) {

                //Name normalize
                $baseName = $this->getBaseEventName($p->event->title);
                try {
                    $year = Carbon::parse($p->time_in)->format('Y');
                } catch (\Exception $e) {
                    continue; // Skip invalid dates
                }

                if (!isset($groupedByEvent[$baseName])) {
                    $groupedByEvent[$baseName] = [];
                }
                if (!isset($groupedByEvent[$baseName][$year])) {
                    $groupedByEvent[$baseName][$year] = 0;
                }
                $groupedByEvent[$baseName][$year]++;
            }
        }

        //Forecast Calculation
        $eventsForecast = [];
        foreach ($groupedByEvent as $eventName => $yearlyData) {
            ksort($yearlyData);
            $years = array_keys($yearlyData);
            $actualCounts = array_values($yearlyData);

            //Sufficient Data Check
            if (count($years) < 2) {
                $eventsForecast[$eventName] = [
                    'message' => 'Insufficient historical data (Needs 2+ years).',
                    'available_years' => count($years),
                    'isOpen' => false
                ];
                continue;
            }

            // Math Calculations
            $movingAvg = $this->calculateMovingAverage($actualCounts, 3);
            $expSmooth = $this->calculateExponentialSmoothing($actualCounts, 0.4); 
            
            // Future Forecasts
            $cleanMovingAvg = array_values(array_filter($movingAvg, fn($v) => !is_null($v)));
            
            $forecastEs = $this->generateForecasts($expSmooth, 3);
            $forecastMa = $this->generateForecasts($cleanMovingAvg, 3);

            $lastYear = (int) end($years);
            $forecastYears = [
                (string) ($lastYear + 1),
                (string) ($lastYear + 2),
                (string) ($lastYear + 3)
            ];

            // Text analysis generate
            $analysis = $this->generatePrescriptiveAnalysis($actualCounts, $forecastEs);

            // Final Structure
            $eventsForecast[$eventName] = [
                'years' => $years,
                'actual' => $actualCounts,
                'moving_average' => $movingAvg,
                'exponential_smoothing' => $expSmooth,
                'forecast_years' => $forecastYears,
                'forecast_exponential' => $forecastEs,
                'forecast_moving_average' => $forecastMa,
                'analysis' => $analysis,
                'isOpen' => false
            ];
        }

        return response()->json(['events' => $eventsForecast]);
    }

    private function getBaseEventName($title) {
        $parts = explode(' ', $title);
        $lastPart = end($parts);
        if (preg_match('/^\d{4}$/', $lastPart)) {
            array_pop($parts);
        }
        return implode(' ', $parts);
    }

    private function calculateMovingAverage($data, $window = 3) {
        $result = [];
        $count = count($data);
        for ($i = 0; $i < $count; $i++) {
            if ($i < $window - 1) {
                $result[] = null;
                continue;
            }
            $slice = array_slice($data, $i - $window + 1, $window);
            $result[] = count($slice) > 0 ? array_sum($slice) / count($slice) : 0;
        }
        return $result;
    }

    private function calculateExponentialSmoothing($data, $alpha = 0.4) {
        if (empty($data)) return [];
        $result = [$data[0]];
        for ($i = 1; $i < count($data); $i++) {
            $result[$i] = $alpha * $data[$i] + (1 - $alpha) * $result[$i - 1];
        }
        return $result;
    }

    private function generateForecasts($smoothedData, $horizon = 3) {
        $count = count($smoothedData);
        if ($count < 2) return array_fill(0, $horizon, 0);

        $lastValue = $smoothedData[$count - 1];
        $prevValue = $smoothedData[$count - 2];
        $trend = $lastValue - $prevValue;

        $forecasts = [];
        for ($i = 1; $i <= $horizon; $i++) {
            $val = $lastValue + ($trend * $i);
            $forecasts[] = max(0, round($val, 2)); // Prevent negative students
        }
        return $forecasts;
    }

    private function generatePrescriptiveAnalysis($actual, $forecast) {
        if (empty($actual) || empty($forecast)) {
            return ['type' => 'neutral', 'label' => 'Unknown', 'text' => 'Insufficient Data'];
        }

        $recentActual = array_slice($actual, -3);
        $avgRecent = count($recentActual) > 0 ? array_sum($recentActual) / count($recentActual) : 0;
        $avgForecast = count($forecast) > 0 ? array_sum($forecast) / count($forecast) : 0;

        if ($avgRecent == 0) return ['type' => 'neutral', 'label' => 'Stable', 'text' => 'No recent activity.'];

        $diffPercent = (($avgForecast - $avgRecent) / $avgRecent) * 100;

        if ($diffPercent > 10) {
            return [
                'type' => 'positive',
                'label' => 'Growth',
                'text' => 'ISUVentra predicts a +' . round($diffPercent, 1) . '% surge based on trends.'
            ];
        } elseif ($diffPercent < -5) {
            return [
                'type' => 'negative',
                'label' => 'Decline',
                'text' => 'ISUVentra predicts a ' . round($diffPercent, 1) . '% drop. Considerations needed.'
            ];
        } else {
            return [
                'type' => 'neutral',
                'label' => 'Stable',
                'text' => 'Attendance is expected to remain consistent with previous years.'
            ];
        }
    }

    public function getDashboardStats()
    {
        //Dashboard Card Counts 
        $totalStudents = Student::count();
        $totalEvents = Event::count();
        $totalParticipations = Participation::count();

        // Main Chart Data (Group by Event)
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