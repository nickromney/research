# Rails 8.1 Server Manager

A fully-featured server management application built with Ruby on Rails 8.1 (latest available version). This application demonstrates modern Rails development practices including:

- User authentication with Devise
- Multi-tenancy with user groups
- SSH connectivity for server management
- Real-time service monitoring
- Automated renewal scripts (SSL certificates, etc.)

## Quick Start

```bash
# Using Docker Compose (recommended)
cd ..
docker-compose up rails-app rails-db

# The application will be available at http://localhost:3000
```

## Features

- **Multi-user authentication** with role-based access control
- **User groups** for team organization
- **Projects** to group servers
- **SSH server management** with connection testing
- **Service monitoring** (systemd, Docker, processes)
- **Renewal automation** for SSL certificates and recurring tasks
- **Real-time status updates** with Hotwire

## Login Credentials

```
Admin: admin@example.com / password123
User: john@example.com / password123
```

## Technology Stack

- Ruby 3.4
- Rails 8.1
- PostgreSQL 16
- Devise (authentication)
- Net::SSH (SSH connectivity)
- Hotwire (reactive UI)
- Bootstrap 5

## Development

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Run server
rails server

# Run console
rails console
```

## Full Documentation

See [SERVER-MANAGER-COMPARISON.md](../SERVER-MANAGER-COMPARISON.md) for a complete comparison with Laravel implementation.
