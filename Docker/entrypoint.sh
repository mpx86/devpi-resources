#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

function initialize_server() {
# Initialize the server directory if not already done
    if [ ! -f "$SERVER_DIR/.serverversion" ]; then
        echo "Initializing devpi server directory at $SERVER_DIR"
        devpi-init --serverdir "$SERVER_DIR"
    else
        echo "Devpi server directory already initialized."
    fi
}

function create_index() {
    : "${DEVPI_PWHASH=password}"
    echo "DEVPI_PWHASH is ${DEVPI_PWHASH}"
    export DEVPI_PWHASH

    # Wait for the server to start
    sleep 6

    # Set up the devpi user and the 'packages' index
    echo "Attempting to use http://localhost:$DEVPI_PORT"
    devpi use http://localhost:$DEVPI_PORT
    echo "Logging in as root"
    devpi login root --password=''
    echo "Setting root password to $DEVPI_PWHASH"
    devpi user -m root "password=$DEVPI_PWHASH"
    # echo "Setting up public index under root"
    # devpi index -y -c root/public pypi_whitelist='*'
    
    echo "Checking if $DEVPI_INTERNAL_USER user exists"
    if ! devpi user -l | grep -q "$DEVPI_INTERNAL_USER"; then
        echo "Creating $DEVPI_INTERNAL_USER user"
        devpi user -c $DEVPI_INTERNAL_USER password="$DEVPI_PWHASH"
    else
        echo "$DEVPI_INTERNAL_USER user already exists."
    fi

    echo "Attempting to log in as $DEVPI_INTERNAL_USER"
    devpi login $DEVPI_INTERNAL_USER --password="$DEVPI_PWHASH"

    echo "Checking if ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME} index exists"
    if ! devpi use ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME}; then
        echo "Creating ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME} index"
        devpi index -c ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME} volatile=False
    else
        echo "Index ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME} already exists."
    fi

    echo "Checking if ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME} index exists"
    if ! devpi use ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME}; then
        echo "Creating ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME} index"
        devpi index -c ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME} volatile=True
    else
        echo "Index ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME} already exists."
    fi

    # echo "Attempting to create $DEVPI_INTERNAL_USER"
    # devpi user -c $DEVPI_INTERNAL_USER password="$DEVPI_PWHASH"
    # sleep 2
    # echo "Attempting to log in as $DEVPI_INTERNAL_USER and create index"
    # devpi login $DEVPI_INTERNAL_USER --password="$DEVPI_PWHASH"
    # sleep 2
    # devpi index -c ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME} volatile=False
    # echo "PROD_DEVPI_INDEX_NAME is set to ${DEVPI_INTERNAL_USER}/${PROD_DEVPI_INDEX_NAME}"
    # devpi index -c ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME} volatile=True
    # echo "PROD_DEVPI_INDEX_NAME is set to ${DEVPI_INTERNAL_USER}/${NONPROD_DEVPI_INDEX_NAME}"
}

function kill_devpi() {
    _PID=$(pgrep devpi-server)
    echo "ENTRYPOINT: Sending SIGTERM to PID $_PID"
    kill -SIGTERM "$_PID"
}

# Activate the virtual environment
source /env/bin/activate

# # Initialize the server directory if not already done
# if [ ! -f "$SERVER_DIR/.serverversion" ]; then
#     echo "Initializing devpi server directory at $SERVER_DIR"
#     devpi-init --serverdir "$SERVER_DIR"
# fi
initialize_server

# Start devpi-server in the background to allow creating users and indices
exec devpi-server --serverdir "$SERVER_DIR" \
    --host 0.0.0.0 \
    --port "$DEVPI_PORT" &

echo "ENTRYPOINT: Installing signal traps"
trap kill_devpi SIGINT SIGTERM

create_index

echo "ENTRYPOINT: Watching devpi-server"
PID=$(pgrep devpi-server)

if [ -z "$PID" ]; then
    echo "ENTRYPOINT: Could not determine PID of devpi-server!"
    exit 1
fi

set +e

while : ; do
    kill -0 "$PID" > /dev/null 2>&1 || break
    sleep 2s
done

echo "ENTRYPOINT: devpi-server died, exiting..."