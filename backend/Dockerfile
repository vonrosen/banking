FROM hhvm/hhvm-proxygen:latest

# Install basic tools needed for development
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create the config directory if it doesn't exist
RUN mkdir -p /etc/hhvm

# Configure HHVM server to use public/index.hack as entry point
RUN echo "hhvm.server.port = 8080" >> /etc/hhvm/server.ini && \
    echo "hhvm.server.source_root = /var/www/public" >> /etc/hhvm/server.ini && \
    echo "hhvm.server.default_document = index.hack" >> /etc/hhvm/server.ini && \
    echo "hhvm.server.error_document404 = index.hack" >> /etc/hhvm/server.ini

# Set working directory
WORKDIR /var/www

# Copy composer files first for better caching
COPY composer.json ./

# Install dependencies
RUN composer install --no-dev --optimize-autoloader || true

# Copy the rest of the application
COPY . .

# Note: For production, uncomment the following line to generate autoload map at build time
# RUN if [ -f vendor/bin/hh-autoload ]; then vendor/bin/hh-autoload; fi

# Expose the web server port and debug port
EXPOSE 8080 8089

# Run HHVM in server mode with config file and VS Code debugger enabled
CMD ["hhvm", "-m", "server", "-c", "/etc/hhvm/server.ini", "-vServer.AllowRunAsRoot=1", "-d", "hhvm.debugger.vs_debug_enable=1", "-d", "hhvm.debugger.vs_debug_listen_port=8089"]
