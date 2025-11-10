# Clear existing data
puts "Clearing existing data..."
Renewal.destroy_all
Service.destroy_all
Server.destroy_all
Project.destroy_all
UserGroupMembership.destroy_all
UserGroup.destroy_all
User.destroy_all

# Create users
puts "Creating users..."
admin = User.create!(
  name: "Admin User",
  email: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: "admin"
)

user1 = User.create!(
  name: "John Doe",
  email: "john@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: "user"
)

user2 = User.create!(
  name: "Jane Smith",
  email: "jane@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: "user"
)

puts "Created #{User.count} users"

# Create user groups
puts "Creating user groups..."
dev_team = UserGroup.create!(
  name: "Development Team",
  description: "Development team members"
)

ops_team = UserGroup.create!(
  name: "Operations Team",
  description: "Operations team members"
)

# Add users to groups
dev_team.add_user(user1, role: 'admin')
dev_team.add_user(user2, role: 'member')
ops_team.add_user(user2, role: 'admin')

puts "Created #{UserGroup.count} user groups"

# Create projects
puts "Creating projects..."
web_project = Project.create!(
  name: "Web Application",
  description: "Production web application infrastructure",
  owner: admin,
  user_group: dev_team
)

api_project = Project.create!(
  name: "API Services",
  description: "Backend API services",
  owner: admin,
  user_group: ops_team
)

personal_project = Project.create!(
  name: "Personal Servers",
  description: "Personal development servers",
  owner: user1
)

puts "Created #{Project.count} projects"

# Create servers
puts "Creating servers..."
web1 = Server.create!(
  name: "Web Server 1",
  hostname: "web1.example.com",
  port: 22,
  username: "deploy",
  description: "Primary web server",
  project: web_project,
  status: "unknown"
)

web2 = Server.create!(
  name: "Web Server 2",
  hostname: "web2.example.com",
  port: 22,
  username: "deploy",
  description: "Secondary web server",
  project: web_project,
  status: "unknown"
)

api1 = Server.create!(
  name: "API Server 1",
  hostname: "api1.example.com",
  port: 22,
  username: "apiuser",
  description: "API backend server",
  project: api_project,
  status: "unknown"
)

db1 = Server.create!(
  name: "Database Server",
  hostname: "db1.example.com",
  port: 22,
  username: "dbadmin",
  description: "PostgreSQL database server",
  project: api_project,
  status: "unknown"
)

dev1 = Server.create!(
  name: "Development Server",
  hostname: "dev.example.com",
  port: 22,
  username: "john",
  description: "Personal development environment",
  project: personal_project,
  status: "unknown"
)

puts "Created #{Server.count} servers"

# Create services
puts "Creating services..."
Service.create!([
  {
    name: "nginx",
    service_type: "systemd",
    server: web1,
    status: "unknown"
  },
  {
    name: "rails",
    service_type: "systemd",
    server: web1,
    status: "unknown"
  },
  {
    name: "nginx",
    service_type: "systemd",
    server: web2,
    status: "unknown"
  },
  {
    name: "rails",
    service_type: "systemd",
    server: web2,
    status: "unknown"
  },
  {
    name: "api-service",
    service_type: "docker",
    server: api1,
    status: "unknown"
  },
  {
    name: "redis",
    service_type: "docker",
    server: api1,
    status: "unknown"
  },
  {
    name: "postgresql",
    service_type: "systemd",
    server: db1,
    status: "unknown"
  },
  {
    name: "pgbouncer",
    service_type: "systemd",
    server: db1,
    status: "unknown"
  }
])

puts "Created #{Service.count} services"

# Create renewals
puts "Creating renewals..."
Renewal.create!([
  {
    name: "SSL Certificate Renewal - Web1",
    renewal_type: "lets_encrypt",
    script: "certbot renew --nginx --non-interactive",
    description: "Renew Let's Encrypt SSL certificates for web1",
    schedule: "monthly",
    server: web1,
    status: "pending",
    next_execution_at: 30.days.from_now
  },
  {
    name: "SSL Certificate Renewal - Web2",
    renewal_type: "lets_encrypt",
    script: "certbot renew --nginx --non-interactive",
    description: "Renew Let's Encrypt SSL certificates for web2",
    schedule: "monthly",
    server: web2,
    status: "pending",
    next_execution_at: 30.days.from_now
  },
  {
    name: "API SSL Certificate",
    renewal_type: "ssl",
    script: "certbot renew --nginx",
    description: "Renew API server SSL certificate",
    schedule: "monthly",
    server: api1,
    status: "pending",
    next_execution_at: 25.days.from_now
  },
  {
    name: "Database Backup Cleanup",
    renewal_type: "custom",
    script: "find /backups -mtime +30 -delete",
    description: "Clean up old database backups",
    schedule: "weekly",
    server: db1,
    status: "pending",
    next_execution_at: 7.days.from_now
  }
])

puts "Created #{Renewal.count} renewals"

puts "\n" + "="*50
puts "Seed data created successfully!"
puts "="*50
puts "\nLogin credentials:"
puts "  Admin: admin@example.com / password123"
puts "  User1: john@example.com / password123"
puts "  User2: jane@example.com / password123"
puts "\n" + "="*50
