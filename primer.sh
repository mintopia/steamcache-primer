#!/bin/bash
RETRIES=3
STEAM_USER="murraymint"
STEAMCMD="/data/primer/steamcmd/steamcmd.sh"
DOWNLOAD_PATH="/data/primer/games/"
APPIDS_SOURCE="/data/primer/appids"
PLATFORMS="windows linux macosx"
PLATFORM_BITS="32 64"

STEAMCMD_DIR="$(dirname "$STEAMCMD")"

if [ -z "$STEAM_USER" ]
then
        echo "Please populate the configuration file in ${CONFIG_FILE}"
        exit -1
fi

if [ -z "$STEAMCMD" ]
then
        echo "Could not locate steamcmd.sh"
        exit -3
fi

$STEAMCMD +login "${STEAM_USER}" +quit || (
        echo "Please check the login details for ${STEAM_USER} and login using $STEAMCMD +login \"${STEAM_USER}\" +quit"
        exit -2
)

while [ $# -gt 1 ]
do
        case "$1" in
                --appids-from-stdin)
                        APPIDS_SOURCE="-"
                        ;;
                --appids)
                        APPIDS_SOURCE="$(mktemp)"
                        shift
                        while echo "$1" | grep -qv "^--"
                        do
                                echo "$1" >> "$APPIDS_SOURCE"
                        done
        esac
        shift
done

cat "$APPIDS_SOURCE" | while read appid
do
        for i in `seq $RETRIES`
        do
                if [ $i -gt 1 ]
                then
                        echo "Retrying, attempt $i"
                fi

                (
                        for platform in $PLATFORMS
                        do
                                for bits in $PLATFORM_BITS
                                do
                                        echo "Downloading AppID ${appid} for ${platform}/${bits}"
                                        cat <<EOF | "$STEAMCMD"
@NoPromptForPassword 1
@sSteamCmdForcePlatformBitness ${bits}
@sSteamCmdForcePlatformType ${platform}
login ${STEAM_USER}
force_install_dir "${DOWNLOAD_PATH}/${appid}"
app_update ${appid}
quit
EOF
                                done
                        done
                ) && break
        done

        if [ "$appid" ]
        then
                rm -rf "${DOWNLOAD_PATH}/${appid}"
        fi
done

