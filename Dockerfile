# Use an official Ruby runtime as the base image
FROM ruby:3.1.4

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    postgresql-server-dev-15 \
    pkg-config \
    postgresql-client \
    iputils-ping \
    default-mysql-client \
    redis-tools \
    curl \
    wget \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

# RUN corepack enable
# RUN yarn set version stable

# Set the working directory
WORKDIR /imtz_aml_auto

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install
ENV PATH="/usr/local/bundle/bin:${PATH}"

# Copy the rest of the application code
COPY . .

# Create necessary directories
RUN mkdir -p tmp/pids log

# Expose port 3000 for the Rails server
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Default command (can be overridden)
CMD ["rails", "server", "-b", "0.0.0.0"]
