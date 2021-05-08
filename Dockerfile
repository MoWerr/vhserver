FROM mowerr/lgsm-base:latest

# We tell the container to download valheim server
ENV GAME=vhserver

# Those ports will be used by the server
# In order to join the server use port 2456 (in-game)
# In order to add the server to favourite list use port 2457 (steam-app)
EXPOSE 2456/udp 2457/udp