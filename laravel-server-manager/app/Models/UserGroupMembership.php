<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserGroupMembership extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'user_group_id', 'role'];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function userGroup()
    {
        return $this->belongsTo(UserGroup::class);
    }
}
