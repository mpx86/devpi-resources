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

# Checking /app/devpi contents
echo "Checking /app/devpi contents"
ls -al /app/devpi/

# Checking /app/venv contents
echo "Checking /app/venv contents"
ls -al /app/venv/

# Set up the devpi user and the 'packages' index
echo "Attempting to use http://localhost:$DEVPI_PORT"
devpi use http://localhost:$DEVPI_PORT

echo "Attempting to create $DEVPI_INTERNAL_USER"
devpi user -c $DEVPI_INTERNAL_USER password="$DEVPI_PWHASH"

echo "Attempting to log in as $DEVPI_INTERNAL_USER and create index"
devpi login $DEVPI_INTERNAL_USER --password="$DEVPI_PWHASH"
sleep 5
devpi index -c packages volatile=True

# Kill the background server
pkill -f "devpi-server"

# Start devpi-server in the foreground with user and index creation restricted to root user
exec devpi-server --serverdir "$SERVER_DIR" \
    --host 0.0.0.0 \
    --port "$DEVPI_PORT" #\
    #--restrict-modify=root