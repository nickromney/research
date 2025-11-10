FROM ruby:3.3.0-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    libpq-dev \
    libvips \
    node-gyp \
    pkg-config \
    python-is-python3 && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /rails

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Precompile assets (skip if it fails - will run at startup)
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile || true

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Remove pre-existing server.pid\n\
rm -f /rails/tmp/pids/server.pid\n\
\n\
# Run database migrations\n\
bundle exec rails db:prepare\n\
\n\
# Seed database if empty\n\
bundle exec rails db:seed\n\
\n\
# Start Rails server\n\
exec bundle exec rails server -b 0.0.0.0' > /rails/docker-entrypoint.sh && \
    chmod +x /rails/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/rails/docker-entrypoint.sh"]
