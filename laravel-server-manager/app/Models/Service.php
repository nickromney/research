<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'service_type', 'check_command',
        'status', 'status_output', 'last_checked_at', 'server_id'
    ];

    protected $casts = [
        'last_checked_at' => 'datetime',
    ];

    // Relationships
    public function server()
    {
        return $this->belongsTo(Server::class);
    }

    // Methods
    public function checkStatus()
    {
        $command = $this->check_command ?? $this->getDefaultCheckCommand();

        $result = $this->server->executeCommand($command);

        if ($result['success']) {
            $output = trim($result['output']);
            $newStatus = $this->determineStatusFromOutput($output);

            $this->update([
                'status' => $newStatus,
                'status_output' => $output,
                'last_checked_at' => now(),
            ]);

            return ['success' => true, 'status' => $newStatus, 'output' => $output];
        } else {
            $this->update([
                'status' => 'unknown',
                'status_output' => $result['error'],
                'last_checked_at' => now(),
            ]);

            return ['success' => false, 'error' => $result['error']];
        }
    }

    protected function getDefaultCheckCommand()
    {
        return match($this->service_type) {
            'systemd' => "systemctl is-active {$this->name}",
            'docker' => "docker ps --filter name={$this->name} --filter status=running --format '{{.Names}}'",
            'process' => "pgrep -f {$this->name} > /dev/null && echo 'running' || echo 'stopped'",
            default => $this->check_command
        };
    }

    protected function determineStatusFromOutput($output)
    {
        return match($this->service_type) {
            'systemd' => str_contains($output, 'active') ? 'running' : 'stopped',
            'docker' => (!empty($output) && str_contains($output, $this->name)) ? 'running' : 'stopped',
            'process' => str_contains($output, 'running') ? 'running' : 'stopped',
            default => preg_match('/running|active|up|ok/i', $output) ? 'running' :
                      (preg_match('/stopped|inactive|down|failed/i', $output) ? 'stopped' : 'unknown')
        };
    }

    // Scopes
    public function scopeRunning($query)
    {
        return $query->where('status', 'running');
    }

    public function scopeStopped($query)
    {
        return $query->where('status', 'stopped');
    }
}
