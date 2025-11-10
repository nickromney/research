<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('renewals', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('renewal_type');
            $table->text('script');
            $table->text('description')->nullable();
            $table->timestamp('last_executed_at')->nullable();
            $table->timestamp('next_execution_at')->nullable();
            $table->string('schedule')->nullable();
            $table->string('status')->default('pending');
            $table->text('last_output')->nullable();
            $table->foreignId('server_id')->constrained()->onDelete('cascade');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('renewals');
    }
};
