<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('servers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('hostname');
            $table->integer('port')->default(22);
            $table->string('username')->nullable();
            $table->text('ssh_key')->nullable();
            $table->string('ssh_key_path')->nullable();
            $table->text('description')->nullable();
            $table->string('status')->default('unknown');
            $table->timestamp('last_checked_at')->nullable();
            $table->foreignId('project_id')->constrained()->onDelete('cascade');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('servers');
    }
};
