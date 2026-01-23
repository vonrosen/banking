FROM hhvm/hhvm-proxygen:latest

# Install basic tools needed for development
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create the config directory if it doesn't exist
RUN mkdir -p /etc/hhvm

# Configure HHVM server
RUN echo "hhvm.server.port = 8080" >> /etc/hhvm/server.ini && \
    echo "hhvm.server.source_root = /var/www" >> /etc/hhvm/server.ini && \
    echo "hhvm.server.default_document = hello.hack" >> /etc/hhvm/server.ini

# Set working directory to the standard web root
WORKDIR /var/www

# Copy the hello script
COPY hello.hack /var/www/hello.hack

# Expose the web server port and debug port
EXPOSE 8080 8089

# Run HHVM in server mode with config file and VS Code debugger enabled
CMD ["hhvm", "-m", "server", "-c", "/etc/hhvm/server.ini", "-vServer.AllowRunAsRoot=1", "-d", "hhvm.debugger.vs_debug_enable=1", "-d", "hhvm.debugger.vs_debug_listen_port=8089"]
