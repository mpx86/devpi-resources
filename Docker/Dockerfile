# Use an official Python base image with Python 3.12
FROM python:3.12-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_INDEX_URL=https://pypi.python.org/simple
ENV PIP_NO_CACHE_DIR=1
ENV PIP_TRUSTED_HOST=127.0.0.1
ENV VENV_DIR=/env
ENV SERVER_DIR=/data/app
ENV DEVPI_PORT=3141
ENV DEVPI_INTERNAL_USER=dbrg
ENV MY_DEVPI_USER=devpi
ENV PROD_DEVPI_INDEX_NAME=packages-prod
ENV NONPROD_DEVPI_INDEX_NAME=packages-nonprod


# Install missing packages
RUN set -eux; \
    \
    apt-get update --quiet; \
    apt-get upgrade --yes; \
    apt-get install --yes --no-install-recommends \
        procps \
    ; \
    rm -rf /var/lib/apt/lists/*
    
# Create devpi user
RUN set -eux; \
    \
    addgroup --system --gid 1000 devpi; \
    adduser --disabled-password --system --uid 1000 --home /data \
        --shell /sbin/nologin --gid 1000 devpi

# Copy requirements
COPY requirements /tmp/requirements/

# Install base dependencies
RUN set -eux; \
    \
    python -m pip install \
        --requirement /tmp/requirements/base.txt

# Create virtualenv
RUN set -eux; \
    \
    python -m venv --upgrade-deps ${VENV_DIR}

# Prepend virtualenv to PATH
ENV PATH=${VENV_DIR}/bin:${PATH}

# Install devpi
RUN set -eux; \
    \
    python -m pip install \
        --requirement /tmp/requirements/devpi.txt

EXPOSE 3141
VOLUME /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER devpi
ENV HOME=${SERVER_DIR}
WORKDIR ${SERVER_DIR}

ENTRYPOINT ["/entrypoint.sh"]
