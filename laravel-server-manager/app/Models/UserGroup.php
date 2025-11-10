<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserGroup extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description'];

    // Relationships
    public function userGroupMemberships()
    {
        return $this->hasMany(UserGroupMembership::class);
    }

    public function users()
    {
        return $this->belongsToMany(User::class, 'user_group_memberships')
                    ->withPivot('role')
                    ->withTimestamps();
    }

    public function projects()
    {
        return $this->hasMany(Project::class);
    }

    // Helper methods
    public function addUser(User $user, string $role = 'member')
    {
        return $this->userGroupMemberships()->create([
            'user_id' => $user->id,
            'role' => $role,
        ]);
    }

    public function removeUser(User $user)
    {
        return $this->userGroupMemberships()->where('user_id', $user->id)->delete();
    }
}
