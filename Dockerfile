###########################################################
# Dockerfile that sets up a Risk of Rain 2 server
###########################################################
FROM steamcmd/steamcmd:debian-13

LABEL authors="Wray <i@wray7.top>"

ARG DEBIAN_FRONTEND=noninteractive

ARG WINE_REL="stable"
#ARG WINE_VER="7.0.0.0~focal-1"

ENV STEAMCMD /usr/bin/steamcmd
ENV STEAMAPPID 1180761
ENV STEAMAPPDIR /root/ror2-dedicated
ENV MODDIR /root/ror2ds-mods

# Default server parameters
ENV R2_PLAYERS 4
ENV R2_HEARTBEAT 0
ENV R2_HOSTNAME "A Risk of Rain 2 dedicated server"
ENV R2_PSW ""
ENV R2_ENABLE_MODS false
ENV R2_SV_PORT 27015
ENV R2_QUERY_PORT 27016
ENV R2_GAMEMODE "ClassicRun"

ENV WINE_REL=$WINE_REL
#ENV WINE_VER=$WINE_VER
# stable, devel, staging
ENV WINE_REPLACE_REL "stable"

# Prepare the environment
RUN set -x \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        wget \
        gnupg2 \
    && wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key - \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources\
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        xauth \
        gettext \
        winbind \
        xvfb \
        lib32gcc-s1 \
    && apt-get install -y --install-recommends --no-install-suggests \
#        winehq-${WINE_REL}=${WINE_VER} \
#        wine-${WINE_REL}=${WINE_VER} \
#        wine-${WINE_REL}-amd64=${WINE_VER} \
#        wine-${WINE_REL}-i386=${WINE_VER} \
        winehq-${WINE_REL} \
        wine-${WINE_REL} \
        wine-${WINE_REL}-amd64 \
        wine-${WINE_REL}-i386 \
    && mkdir -p "${STEAMAPPDIR}" \
    && "${STEAMCMD}" +force_install_dir /home/steam/steamworks_sdk +login anonymous \
        +@sSteamCmdForcePlatformType windows +app_update 1007 +quit \
    && cp /home/steam/steamworks_sdk/*64.dll "${STEAMAPPDIR}"/ \
#    && "${STEAMCMD}" +force_install_dir ${STEAMAPPDIR} +login anonymous \
#        +@sSteamCmdForcePlatformType windows +app_update ${STEAMAPPID} validate  +quit \
    && apt-get remove --purge -y \
        wget \
        gnupg2 \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY entry.sh ${STEAMAPPDIR}/entry.sh
COPY default_config.cfg ${STEAMAPPDIR}/default_config.cfg
RUN  mkdir -p "${STEAMAPPDIR}/Risk of Rain 2_Data/Config/" \
     && cp "${STEAMAPPDIR}/default_config.cfg" "${STEAMAPPDIR}/Risk of Rain 2_Data/Config/server.cfg"

WORKDIR ${STEAMAPPDIR}

# Check for message to see if server is ready
HEALTHCHECK --interval=10s --timeout=5s \
    CMD grep "Steamworks Server IP discovered" "${STEAMAPPDIR}/entry.log" || exit 1
# Start the server
ENTRYPOINT "${STEAMAPPDIR}/entry.sh"

# Declare default exposed ports
EXPOSE ${R2_SV_PORT}/udp
EXPOSE ${R2_QUERY_PORT}/udp
