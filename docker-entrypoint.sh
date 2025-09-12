#!/bin/bash
set -e

# ---------------------------
# Ensure ownership
# ---------------------------
chown -R freeswitch:freeswitch /usr/local/freeswitch

# ---------------------------
# Add mod_voicechanger to modules.conf.xml if missing
# ---------------------------
MOD_CONF="/usr/local/freeswitch/conf/autoload_configs/modules.conf.xml"
if ! grep -q "mod_voicechanger" "$MOD_CONF"; then
    sed -i '/<modules>/a \ \ <load module="mod_voicechanger"/>' "$MOD_CONF"
fi

# ---------------------------
# Verify module file exists
# ---------------------------
if [ ! -f /usr/local/freeswitch/mod/mod_voicechanger.so ]; then
    echo "ERROR: mod_voicechanger.so not found in /usr/local/freeswitch/mod/"
    exit 1
fi

# ---------------------------
# Start FreeSWITCH in background
# ---------------------------
/usr/sbin/freeswitch -u freeswitch -g freeswitch -nonat &

# Wait for FreeSWITCH to fully start
sleep 30

# Load mod_voicechanger via fs_cli
fs_cli -x "load mod_voicechanger"

# ---------------------------
# Start Spring Boot backend inside screen
# ---------------------------
screen -dmS springboot bash -c "java -jar /usr/local/src/VoicechnagerBackend/target/VoicechnagerBackend-1.0-SNAPSHOT.jar"

# ---------------------------
# Keep container alive (attach to FreeSWITCH process)
# ---------------------------
wait
