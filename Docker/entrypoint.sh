#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Output environment variables for verification
echo "SERVER_DIR: $SERVER_DIR"
echo "DEVPI_PORT: $DEVPI_PORT"
echo "DEVPI_INTERNAL_USER: $DEVPI_INTERNAL_USER"
echo "DEVPI_PWHASH: $DEVPI_PWHASH"

# Ensure the devpi-server directory exists
echo "Checking to see if SERVER_DIR $SERVER_DIR EXISTS"
echo "Printing working directory"
pwd
echo "Checking file structure and permissions"
ls -l >&1
mkdir -p "$SERVER_DIR"
ls -l "$SERVER_DIR" >&1  # Check contents after creating the directory

# Initialize the server directory if not already done
if [ ! -f "$SERVER_DIR/.serverversion" ]; then
    echo "Initializing devpi server directory at $SERVER_DIR"
    devpi-init --serverdir "$SERVER_DIR" --no-root-pypi
fi

# Start devpi-server in the background to allow creating users and indices
devpi-server --serverdir "$SERVER_DIR" \
    --host 0.0.0.0 \
    --port "$DEVPI_PORT" \
    --restrict-modify=root &

# Wait for the server to start
sleep 5

# Set up the devpi user and the 'packages' index
devpi use http://localhost:$DEVPI_PORT
echo "Attempting to create user with hashed password of $DEVPI_PWHASH:"
devpi user -c $DEVPI_INTERNAL_USER password="$DEVPI_PWHASH"
echo "Attempting to log in as user:"
devpi login $DEVPI_INTERNAL_USER --password="$DEVPI_PWHASH"
echo "Attempting to create index:"
devpi index -c $DEVPI_INTERNAL_USER/packages

# Kill the background server
pkill -f "devpi-server"

# Start devpi-server with the required options
exec devpi-server --serverdir "$SERVER_DIR" \
    --host 0.0.0.0 \
    --port "$DEVPI_PORT" \
    --restrict-modify=root