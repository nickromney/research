# Laravel 11 Server Manager

A fully-featured server management application built with Laravel 11. This application demonstrates modern Laravel development practices including:

- User authentication with Laravel Breeze
- Multi-tenancy with user groups
- SSH connectivity for server management
- Real-time service monitoring
- Automated renewal scripts (SSL certificates, etc.)

## Quick Start

```bash
# Using Docker Compose (recommended)
cd ..
docker-compose up laravel-app laravel-db

# The application will be available at http://localhost:8080
```

## Features

- **Multi-user authentication** with role-based access control
- **User groups** for team organization
- **Projects** to group servers
- **SSH server management** with connection testing
- **Service monitoring** (systemd, Docker, processes)
- **Renewal automation** for SSL certificates and recurring tasks
- **Real-time status updates**

## Login Credentials

```
Admin: admin@example.com / password123
User: john@example.com / password123
```

## Technology Stack

- PHP 8.2
- Laravel 11.0
- PostgreSQL 16
- Laravel Breeze (authentication)
- phpseclib (SSH connectivity)
- Bootstrap 5

## Development

```bash
# Install dependencies
composer install

# Setup database
php artisan migrate --seed

# Run server
php artisan serve

# Tinker (Laravel console)
php artisan tinker
```

## Full Documentation

See [SERVER-MANAGER-COMPARISON.md](../SERVER-MANAGER-COMPARISON.md) for a complete comparison with Rails implementation.
