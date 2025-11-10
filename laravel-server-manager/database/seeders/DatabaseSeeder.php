<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\UserGroup;
use App\Models\Project;
use App\Models\Server;
use App\Models\Service;
use App\Models\Renewal;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Clear existing data
        Renewal::query()->delete();
        Service::query()->delete();
        Server::query()->delete();
        Project::query()->delete();
        UserGroup::query()->delete();
        User::query()->delete();

        // Create users
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);

        $user1 = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
        ]);

        $user2 = User::create([
            'name' => 'Jane Smith',
            'email' => 'jane@example.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
        ]);

        // Create user groups
        $devTeam = UserGroup::create([
            'name' => 'Development Team',
            'description' => 'Development team members',
        ]);

        $opsTeam = UserGroup::create([
            'name' => 'Operations Team',
            'description' => 'Operations team members',
        ]);

        // Add users to groups
        $devTeam->addUser($user1, 'admin');
        $devTeam->addUser($user2, 'member');
        $opsTeam->addUser($user2, 'admin');

        // Create projects
        $webProject = Project::create([
            'name' => 'Web Application',
            'description' => 'Production web application infrastructure',
            'owner_id' => $admin->id,
            'user_group_id' => $devTeam->id,
        ]);

        $apiProject = Project::create([
            'name' => 'API Services',
            'description' => 'Backend API services',
            'owner_id' => $admin->id,
            'user_group_id' => $opsTeam->id,
        ]);

        $personalProject = Project::create([
            'name' => 'Personal Servers',
            'description' => 'Personal development servers',
            'owner_id' => $user1->id,
        ]);

        // Create servers
        $web1 = Server::create([
            'name' => 'Web Server 1',
            'hostname' => 'web1.example.com',
            'port' => 22,
            'username' => 'deploy',
            'description' => 'Primary web server',
            'project_id' => $webProject->id,
        ]);

        $web2 = Server::create([
            'name' => 'Web Server 2',
            'hostname' => 'web2.example.com',
            'port' => 22,
            'username' => 'deploy',
            'description' => 'Secondary web server',
            'project_id' => $webProject->id,
        ]);

        $api1 = Server::create([
            'name' => 'API Server 1',
            'hostname' => 'api1.example.com',
            'port' => 22,
            'username' => 'apiuser',
            'description' => 'API backend server',
            'project_id' => $apiProject->id,
        ]);

        $db1 = Server::create([
            'name' => 'Database Server',
            'hostname' => 'db1.example.com',
            'port' => 22,
            'username' => 'dbadmin',
            'description' => 'PostgreSQL database server',
            'project_id' => $apiProject->id,
        ]);

        // Create services
        Service::create(['name' => 'nginx', 'service_type' => 'systemd', 'server_id' => $web1->id]);
        Service::create(['name' => 'php-fpm', 'service_type' => 'systemd', 'server_id' => $web1->id]);
        Service::create(['name' => 'nginx', 'service_type' => 'systemd', 'server_id' => $web2->id]);
        Service::create(['name' => 'php-fpm', 'service_type' => 'systemd', 'server_id' => $web2->id]);
        Service::create(['name' => 'api-service', 'service_type' => 'docker', 'server_id' => $api1->id]);
        Service::create(['name' => 'redis', 'service_type' => 'docker', 'server_id' => $api1->id]);
        Service::create(['name' => 'postgresql', 'service_type' => 'systemd', 'server_id' => $db1->id]);

        // Create renewals
        Renewal::create([
            'name' => 'SSL Certificate Renewal - Web1',
            'renewal_type' => 'lets_encrypt',
            'script' => 'certbot renew --nginx --non-interactive',
            'description' => 'Renew Let\'s Encrypt SSL certificates',
            'schedule' => 'monthly',
            'server_id' => $web1->id,
            'next_execution_at' => now()->addDays(30),
        ]);

        Renewal::create([
            'name' => 'SSL Certificate Renewal - Web2',
            'renewal_type' => 'lets_encrypt',
            'script' => 'certbot renew --nginx --non-interactive',
            'description' => 'Renew Let\'s Encrypt SSL certificates',
            'schedule' => 'monthly',
            'server_id' => $web2->id,
            'next_execution_at' => now()->addDays(30),
        ]);

        $this->command->info('Database seeded successfully!');
        $this->command->info('Admin: admin@example.com / password123');
        $this->command->info('User1: john@example.com / password123');
        $this->command->info('User2: jane@example.com / password123');
    }
}
