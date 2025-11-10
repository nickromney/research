<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\ServerController;
use App\Http\Controllers\ServiceController;
use App\Http\Controllers\RenewalController;
use App\Http\Controllers\UserGroupController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('dashboard');
});

Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::resource('projects', ProjectController::class);
    Route::resource('servers', ServerController::class);
    Route::resource('renewals', RenewalController::class);
    Route::resource('user-groups', UserGroupController::class);

    Route::post('/servers/{server}/test-connection', [ServerController::class, 'testConnection'])->name('servers.test-connection');
    Route::post('/servers/{server}/check-services', [ServerController::class, 'checkServices'])->name('servers.check-services');

    Route::post('/servers/{server}/services', [ServiceController::class, 'store'])->name('servers.services.store');
    Route::delete('/servers/{server}/services/{service}', [ServiceController::class, 'destroy'])->name('servers.services.destroy');
    Route::post('/servers/{server}/services/{service}/check', [ServiceController::class, 'check'])->name('servers.services.check');

    Route::post('/renewals/{renewal}/execute', [RenewalController::class, 'execute'])->name('renewals.execute');
    Route::post('/renewals/{renewal}/test', [RenewalController::class, 'test'])->name('renewals.test');
});

require __DIR__.'/auth.php';
