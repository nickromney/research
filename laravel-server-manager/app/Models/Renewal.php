<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Renewal extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'renewal_type', 'script', 'description',
        'last_executed_at', 'next_execution_at', 'schedule',
        'status', 'last_output', 'server_id'
    ];

    protected $casts = [
        'last_executed_at' => 'datetime',
        'next_execution_at' => 'datetime',
    ];

    // Relationships
    public function server()
    {
        return $this->belongsTo(Server::class);
    }

    // Methods
    public function execute()
    {
        $this->update(['status' => 'running']);

        $result = $this->server->executeCommand($this->script);

        if ($result['success']) {
            $this->update([
                'status' => 'success',
                'last_executed_at' => now(),
                'last_output' => $result['output'],
                'next_execution_at' => $this->calculateNextExecution(),
            ]);

            return ['success' => true, 'output' => $result['output']];
        } else {
            $this->update([
                'status' => 'failed',
                'last_executed_at' => now(),
                'last_output' => $result['error'],
            ]);

            return ['success' => false, 'error' => $result['error']];
        }
    }

    public function testExecution()
    {
        return $this->server->executeCommand($this->script);
    }

    public function isOverdue()
    {
        return $this->next_execution_at && $this->next_execution_at->isPast();
    }

    protected function calculateNextExecution()
    {
        if (!$this->schedule) {
            return null;
        }

        return match($this->schedule) {
            'daily' => now()->addDay(),
            'weekly' => now()->addWeek(),
            'monthly' => now()->addMonth(),
            default => preg_match('/^every_(\d+)_days$/', $this->schedule, $matches)
                ? now()->addDays((int)$matches[1])
                : null
        };
    }

    // Scopes
    public function scopeDueForExecution($query)
    {
        return $query->where('next_execution_at', '<=', now());
    }
}
