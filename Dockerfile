FROM mowerr/ubuntu-base:18.04

# Default user and user group will be adapted to those values
ARG UID=1000
ARG GID=1000

# Adapt UID and GID values
RUN set -x && \
    usermod -o -u ${UID} husky && \
    groupmod -o -g ${GID} husky

# Update the package and install all dependencies. 
RUN set -x && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \ 
        iproute2 \
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
    rm -rf /var/lib/apt/lists/*

# Directory that will be used for LinuxGSM
ENV SERVERDIR="/data/vhserver"

# Define volume for all 'runtime' files
VOLUME ["/data"]

# Those ports will be used by the server
# In order to join the server use port 2456 (in-game)
# In order to add the server to favourite list use port 2457 (steam-app)
EXPOSE 2456/udp 2457/udp

COPY root/ /