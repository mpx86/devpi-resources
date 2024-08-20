# Use an official Python base image with Python 3.10
FROM python:3.10-slim

# Set environment variables
ENV DEVPI_USER=devpi
ENV DEVPI_INTERNAL_USER=contoso
ENV SERVER_DIR=/app/devpi
ENV DEVPI_PORT=3141
ENV VENV_DIR=/app/venv

# Create a non-root user to run the application
RUN useradd -m -s /bin/bash $DEVPI_USER

# Create the necessary directories and set the right permissions
RUN mkdir -p $SERVER_DIR $VENV_DIR && \
    chown -R $DEVPI_USER:$DEVPI_USER $SERVER_DIR $VENV_DIR

# Create a virtual environment and install devpi-server, devpi-client, and devpi-web as root
RUN python3 -m venv $VENV_DIR && \
    $VENV_DIR/bin/pip install --no-cache-dir \
    devpi-server \
    devpi-client \
    devpi-web

# Change ownership of the venv directory to the devpi user
RUN chown -R $DEVPI_USER:$DEVPI_USER $VENV_DIR

# Switch to the non-root user
USER $DEVPI_USER

# Set the working directory
WORKDIR $SERVER_DIR

# Copy the entrypoint script to the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Ensure the script is executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the port used by Devpi
EXPOSE $DEVPI_PORT

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
