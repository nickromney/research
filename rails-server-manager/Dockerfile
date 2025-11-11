FROM ruby:3.4-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    libpq-dev \
    libvips \
    libyaml-dev \
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
COPY Gemfile ./
RUN bundle install

# Copy application code
COPY . .

# Precompile assets (skip if it fails - will run at startup)
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile || true

# Create startup script
RUN printf '#!/bin/bash\nset -e\n\nrm -f /rails/tmp/pids/server.pid\nbundle exec rake db:prepare\nbundle exec rake db:seed\nexec bundle exec rackup config.ru -o 0.0.0.0 -p 3000\n' > /rails/docker-entrypoint.sh && \
    chmod +x /rails/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/rails/docker-entrypoint.sh"]
