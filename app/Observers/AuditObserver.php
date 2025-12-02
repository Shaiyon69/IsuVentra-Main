<?php

namespace App\Observers;

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

class AuditObserver
{
    public function created(Model $model)
    {
        $this->saveLog($model, 'Created', "Created new " . class_basename($model));
    }

    public function updated(Model $model)
    {
        $this->saveLog($model, 'Updated', "Updated " . class_basename($model) . " details");
    }

    public function deleted(Model $model)
    {
        $this->saveLog($model, 'Deleted', "Deleted " . class_basename($model) . " record");
    }

    private function saveLog($model, $action, $description)
    {
        // Try to find a readable name (e.g. $event->title or $student->name)
        // If not found, fallback to the ID (e.g. "Event #5")
        $name = $model->name ?? $model->title ?? ('#' . $model->id);

        AuditLog::create([
            'user_id'     => Auth::id(), // Current Admin ID
            'action'      => $action,
            'activitylog' => "$description: $name", // e.g. "Created new Event: Tech Fest"
        ]);
    }
}
