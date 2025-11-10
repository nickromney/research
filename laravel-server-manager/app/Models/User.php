<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // Relationships
    public function userGroupMemberships()
    {
        return $this->hasMany(UserGroupMembership::class);
    }

    public function userGroups()
    {
        return $this->belongsToMany(UserGroup::class, 'user_group_memberships')
                    ->withPivot('role')
                    ->withTimestamps();
    }

    public function ownedProjects()
    {
        return $this->hasMany(Project::class, 'owner_id');
    }

    // Helper methods
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function canAccessProject(Project $project): bool
    {
        if ($this->isAdmin()) {
            return true;
        }

        if ($project->owner_id === $this->id) {
            return true;
        }

        if ($project->user_group_id && $this->userGroups()->where('user_groups.id', $project->user_group_id)->exists()) {
            return true;
        }

        return false;
    }
}
