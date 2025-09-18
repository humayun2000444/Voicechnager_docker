# FreeSWITCH Docker Setup

This repository contains a Docker setup for FreeSWITCH 1.10.11 with voice changing capabilities.

## Requirements

- Docker
- Docker Compose
- Root access to the host system

## Initial Setup

### 1. System Preparation

```bash
sudo su
apt update
apt upgrade -y
```

### 2. Install Docker (if not already installed)

Follow the official Docker installation guide for your system or use the convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### 3. Clone and Build

```bash
git clone https://github.com/humayun2000444/Voicechnager_docker.git
cd Voicechnager_docker
docker compose up --build -d
```

## Configuration

### 1. Install Required Tools in Container

```bash
docker exec -it -u root Voice_freeswitch bash
apt install nano
exit
```

### 2. Configure Dialplan

Enter the container and edit the dialplan configuration:

```bash
docker exec -it Voice_freeswitch bash
nano /usr/local/freeswitch/conf/dialplan/default.xml
```

**Add the Voice context before the default context:**

```xml
<context name="Voice">
  <extension name="outbound-all-numbers">
    <condition field="destination_number" expression="^\d+$">
      <action application="set" data="hangup_after_bridge=true"/>
      <action application="bridge" data="user/${destination_number},sofia/gateway/commpeak/${destination_number}"/>
    </condition>
  </extension>
</context>
```

**Add this extension inside the default context:**

```xml
<extension name="park">
  <condition expression="^\+?\d+$" field="destination_number">
    <action application="park"/>
  </condition>
</extension>
```

### 3. Configure ACL (Access Control List)

Edit the ACL configuration to allow all IPs:

```bash
nano /usr/local/freeswitch/conf/autoload_configs/acl.conf.xml
```

**Add this line under the domains list:**

```xml
<node type="allow" cidr="0.0.0.0/0"/>
```

**Example configuration:**

```xml
<list name="domains" default="deny">
  <!-- domain= is special it scans the domain from the directory to build the ACL -->
  <node type="allow" domain="$${domain}"/>
  <node type="allow" cidr="0.0.0.0/0"/>
  <!-- use cidr= if you wish to allow ip ranges to this domains acl. -->
  <!-- <node type="allow" cidr="192.168.0.0/24"/> -->
</list>
```

### 4. Configure SIP Gateway (Commpeak)

Create the gateway configuration file:

```bash
nano /usr/local/freeswitch/conf/sip_profiles/external/sip.compeak.com.xml
```

**Add the following configuration:**

```xml
<include>
  <gateway name="commpeak">
    <!-- SIP trunk credentials -->
    <param name="username" value="addyourusername"/>
    <param name="password" value="addpassword"/>
    <param name="realm" value="sip.commpeak.com"/>
    <param name="proxy" value="sip.commpeak.com"/>
    <param name="register" value="true"/>
    <param name="expire-seconds" value="3600"/>
    <param name="retry-seconds" value="30"/>
    <param name="context" value="from-commpeak"/>
  </gateway>
</include>
```

**Important:** Replace `addyourusername` and `addpassword` with your actual Commpeak credentials.

### 5. Apply Configuration Changes

Connect to FreeSWITCH CLI and reload the configuration:

```bash
fs_cli
```

**In the FreeSWITCH CLI, run these commands:**

```
reloadxml
reloadacl
sofia profile external rescan
sofia profile external restart
```

## Basic Operations

### Container Management

**Check container logs:**
```bash
docker logs -f Voice_freeswitch
```

**Enter the container:**
```bash
docker exec -it Voice_freeswitch /bin/bash
```

**Connect to FreeSWITCH CLI:**
```bash
docker exec -it Voice_freeswitch fs_cli
```

**Restart the container:**
```bash
docker compose down
docker compose up -d
```

**Stop the container:**
```bash
docker compose down
```

## Voice API

The voice changing API is available at:

**Endpoint:**
```
http://{server-ip}:8080/set-voice-by-email?email=string&code=int

For the given VM, it will be using the NGINX Proxypass
http://{VM-IP}/api/set-voice-by-email?email=string&code=int
```

**Example Usage:**
```
http://{server-ip}:8080/set-voice-by-email?email=humu123-gmail-com&code=123

Using Proxypass
http://{VM-IP}/api/set-voice-by-email?email=humu123-gmail-com&code=123
```

## Ports Exposed

* `52318` TCP/UDP: Internal SIP (mapped from container port 5060)
* `5080` TCP/UDP: External SIP
* `8021` TCP: Event Socket Layer (ESL)
* `8080` TCP: Web interface (if needed)

## Notes

* FreeSWITCH runs as a non-root user inside the container
* Make sure to replace placeholder credentials with actual values
* The Voice context allows outbound calls through the Commpeak gateway
* ACL is configured to allow all IPs for development purposes - restrict in production
* Voice codes can be set via the API endpoint for different voice effects

## Troubleshooting

**If you encounter issues:**

1. Check container logs: `docker logs Voice_freeswitch`
2. Verify gateway registration: In fs_cli run `sofia status gateway commpeak`
3. Test SIP registration: `sofia profile external gwlist up`
4. Restart FreeSWITCH: `docker exec -it Voice_freeswitch fs_cli -x "shutdown restart"`

## Security Considerations

⚠️ **Warning:** This configuration allows all IPs (`0.0.0.0/0`) which is suitable for development but should be restricted in production environments. Always use proper authentication and IP restrictions for production deployments.
