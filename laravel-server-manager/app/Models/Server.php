<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use phpseclib3\Net\SSH2;
use phpseclib3\Crypt\PublicKeyLoader;

class Server extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'hostname', 'port', 'username',
        'ssh_key', 'ssh_key_path', 'description',
        'status', 'last_checked_at', 'project_id'
    ];

    protected $casts = [
        'last_checked_at' => 'datetime',
    ];

    // Relationships
    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function services()
    {
        return $this->hasMany(Service::class);
    }

    public function renewals()
    {
        return $this->hasMany(Renewal::class);
    }

    // SSH methods
    public function testConnection()
    {
        try {
            $result = $this->executeCommand('echo "Connection successful"');

            $this->update([
                'status' => 'online',
                'last_checked_at' => now(),
            ]);

            return [
                'success' => true,
                'message' => 'Connection successful',
                'output' => $result['output'] ?? ''
            ];
        } catch (\Exception $e) {
            $this->update([
                'status' => 'offline',
                'last_checked_at' => now(),
            ]);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }
    }

    public function executeCommand(string $command)
    {
        try {
            $ssh = new SSH2($this->hostname, $this->port);

            if ($this->ssh_key) {
                $key = PublicKeyLoader::load($this->ssh_key);
                if (!$ssh->login($this->username, $key)) {
                    throw new \Exception('SSH authentication failed');
                }
            } elseif ($this->ssh_key_path && file_exists($this->ssh_key_path)) {
                $key = PublicKeyLoader::load(file_get_contents($this->ssh_key_path));
                if (!$ssh->login($this->username, $key)) {
                    throw new \Exception('SSH authentication failed');
                }
            } else {
                throw new \Exception('No SSH authentication method configured');
            }

            $output = $ssh->exec($command);

            return [
                'success' => true,
                'output' => $output
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    public function checkAllServices()
    {
        foreach ($this->services as $service) {
            $service->checkStatus();
        }
    }

    // Scopes
    public function scopeOnline($query)
    {
        return $query->where('status', 'online');
    }

    public function scopeOffline($query)
    {
        return $query->where('status', 'offline');
    }
}
