# Use an official Python base image with Python 3.10
FROM python:3.10-slim

# Set environment variables for non-root user
ENV DEVPI_USER=devpi
ENV DEVPI_INTERNAL_USER=contoso
ENV SERVER_DIR=/data/devpi
ENV DEVPI_PORT=3141

# Install system dependencies (if any are needed for devpi)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install devpi-server, devpi-client, and devpi-web
RUN pip install --no-cache-dir \
    devpi-server \
    devpi-client \
    devpi-web

# Create a non-root user to run the application
RUN useradd -m -s /bin/bash $DEVPI_USER

# Create the necessary directories and set the right permissions
RUN mkdir -p $SERVER_DIR && \
    chown -R $DEVPI_USER:$DEVPI_USER $SERVER_DIR

# Expose the port used by Devpi
EXPOSE $DEVPI_PORT

# Switch to the non-root user
USER $DEVPI_USER

# Set the working directory
WORKDIR $SERVER_DIR

# Copy the entrypoint script to the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to the script
ENTRYPOINT ["entrypoint.sh"]
