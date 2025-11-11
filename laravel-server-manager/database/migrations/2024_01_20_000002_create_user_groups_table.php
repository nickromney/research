<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('user_group_memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_group_id')->constrained()->onDelete('cascade');
            $table->enum('role', ['member', 'admin'])->default('member');
            $table->timestamps();

            $table->unique(['user_id', 'user_group_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_group_memberships');
        Schema::dropIfExists('user_groups');
    }
};
