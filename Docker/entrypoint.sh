#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Activate the virtual environment
source /app/venv/bin/activate

# Initialize the server directory if not already done
if [ ! -f "$SERVER_DIR/.serverversion" ]; then
    echo "Initializing devpi server directory at $SERVER_DIR"
    devpi-init --serverdir "$SERVER_DIR" --no-root-pypi
fi

# Start devpi-server in the background to allow creating users and indices
devpi-server --serverdir "$SERVER_DIR" \
    --host 0.0.0.0 \
    --port "$DEVPI_PORT" &

# Wait for the server to start
sleep 5

# Set up the devpi user and the 'packages' index
devpi use http://localhost:$DEVPI_PORT
devpi user -c $DEVPI_INTERNAL_USER password="$DEVPI_PWHASH"
devpi login $DEVPI_INTERNAL_USER --password="$DEVPI_PWHASH"
devpi index -c $DEVPI_INTERNAL_USER/packages volatile=True

# Kill the background server
pkill -f "devpi-server"

# Start devpi-server with the required options
exec devpi-server --serverdir "$SERVER_DIR" \
    --host 0.0.0.0 \
    --port "$DEVPI_PORT" \
    --restrict-modify=root