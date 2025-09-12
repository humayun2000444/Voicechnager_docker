#!/bin/bash
set -e

# ---------------------------
# Configure Event Socket
# ---------------------------
cat > /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml <<EOL
<configuration name="event_socket.conf" description="Socket Client">
  <settings>
    <param name="listen-ip" value="0.0.0.0"/>
    <param name="listen-port" value="8021"/>
    <param name="password" value="ClueCon"/>
    <param name="apply-inbound-acl" value="lan"/>
    <param name="tls" value="false"/>
    <param name="ip-version" value="4"/>
  </settings>
</configuration>
EOL

chown -R freeswitch:freeswitch /usr/local/freeswitch

MOD_CONF="/usr/local/freeswitch/conf/autoload_configs/modules.conf.xml"
if ! grep -q "mod_voicechanger" "$MOD_CONF"; then
    sed -i '/<modules>/a \ \ <load module="mod_voicechanger"/>' "$MOD_CONF"
fi

if [ ! -f /usr/local/freeswitch/mod/mod_voicechanger.so ]; then
    echo "ERROR: mod_voicechanger.so not found"
    exit 1
fi

# ---------------------------
# Start FreeSWITCH in background
# ---------------------------
/usr/sbin/freeswitch -u freeswitch -g freeswitch -nonat &

sleep 30
fs_cli -x "load mod_voicechanger"

# ---------------------------
# Start Spring Boot inside screen
# ---------------------------
JAR_FILE=$(ls /usr/local/src/VoicechnagerBackend/target/*.jar | head -n 1)
if [ ! -f "$JAR_FILE" ]; then
    echo "ERROR: Spring Boot JAR not found!"
    exit 1
fi

# Start screen session named 'springboot'
screen -dmS springboot java -jar "$JAR_FILE"

echo "Spring Boot started in screen session 'springboot'."
echo "Attach with: screen -r springboot"

# ---------------------------
# Keep container alive
# ---------------------------
tail -f /dev/null
