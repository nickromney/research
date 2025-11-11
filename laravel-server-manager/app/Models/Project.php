<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'owner_id', 'user_group_id'];

    // Relationships
    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function userGroup()
    {
        return $this->belongsTo(UserGroup::class);
    }

    public function servers()
    {
        return $this->hasMany(Server::class);
    }

    // Helper methods
    public function serversStatusSummary()
    {
        return [
            'online' => $this->servers()->where('status', 'online')->count(),
            'offline' => $this->servers()->where('status', 'offline')->count(),
            'unknown' => $this->servers()->where('status', 'unknown')->count(),
        ];
    }
}
