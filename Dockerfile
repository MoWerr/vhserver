FROM ubuntu:18.04

# Default values are suitable for Unraid usage
# If you will mount drives manually and need to use other values,
# you can alway specify '--user' argument during conatiner creation
ARG UID=99
ARG GID=100

# LinuxGSM requires xterm
ENV TERM="xterm" \
    # The umask will be updated during runtime
    # Unspecified value will leave umask value as is
    UMASK=""

# Update the package and install all dependencies
RUN set -x && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends --no-install-suggests \ 
        locales \
        iproute2 \
        locales \
        ca-certificates \
        wget \
        curl \
        file \
        python3 \
        bsdmainutils \
        unzip \
        binutils \
        bc \
        jq \
        tmux \
        netcat \
        cpio \
        lib32gcc1 \
        lib32stdc++6 \
        libsdl2-2.0-0:i386 \
    && \
    # Cleanup
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    # Generate locale files for en_US
    locale-gen en_US.UTF-8

# Set locale envs
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US \
    LC_ALL=en_US.UTF-8 \
    # Folder that will store all runtime data
    HOME="/data"

# Folders that will be used for volume mounting
ENV STEAMDIR="${HOME}/steamcmd" \
    SERVERDIR="${HOME}/server"

# Folders with 'specific' steam locations
ENV STEAMCMDDIR="${STEAMDIR}/steamcmd" \
    LOCALDIR="${STEAMDIR}/.local" \
    TEMPDIR="${STEAMDIR}/tmp" \
    # Folder with valheim configuration
    CONFIGDIR="${SERVERDIR}/.config"

# Create directories that will be used for downloaded data
# and give our default user an ownership
RUN set -x && \
    mkdir -p ${STEAMDIR} && \
    mkdir -p ${STEAMCMDDIR} && \
    mkdir -p ${LOCALDIR} && \
    mkdir -p ${SERVERDIR} && \
    mkdir -p ${CONFIGDIR} && \
    # Give default user an ownership for mount directories
    # all other locations should be relative to those
    # or created with symbolic links
    chown -R ${UID}:${GID} ${STEAMDIR} && \
    chown -R ${UID}:${GID} ${SERVERDIR} && \
    # Make links for steam directories so the lgsm will able to find them
    ln -s ${STEAMDIR} ${HOME}/.steam && \
    ln -s ${LOCALDIR} ${HOME}/.local && \
    # Make links for temp folder, so the applications will be able to use it
    rm -rf /tmp && ln -s ${TEMPDIR} /tmp && \
    # Make link for configuration files for the vhserver itself
    ln -s ${CONFIGDIR} ${HOME}/.config

# Define volumes for steamcmd and server files
# They will be filed during the container runtime
VOLUME [${STEAMDIR}]
VOLUME [${SERVERDIR}]

# Those ports will be used by the server
# In order to join the server use port 2456 (in-game)
# In order to add the server to favourite list use port 2457 (steam-app)
EXPOSE 2456/udp
EXPOSE 2457/udp

# Switch to default user
USER ${UID}:${GID}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]