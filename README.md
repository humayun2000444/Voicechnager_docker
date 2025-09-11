# FreeSWITCH Docker Setup

This repository contains a Docker setup for FreeSWITCH 1.10.11 on Ubuntu 22.04.

## Requirements

- Docker
- Docker Compose

## How to Run

1. **Clone the repository**:

```bash
git clone https://github.com/AkibHossainOmi/Freeswitch-Docker.git
cd Freeswitch-Docker
````

2. **Build and start the container**:

```bash
docker-compose up --build -d
```

3. **Check container logs**:

```bash
docker logs -f freeswitch
```

4. **Connect to FreeSWITCH CLI**:

```bash
docker exec -it freeswitch fs_cli
```

5. **Stop the container**:

```bash
docker-compose down
```

## Configure Event Socket

1. Enter the container:

```bash
docker exec -it freeswitch /bin/bash
```

2. Open the `event_socket.conf.xml` file. If `nano` is unavailable, use `vi`:

```bash
vi /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
```

3. Replace its contents with:

```xml
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
```

4. Restart FreeSWITCH the container:

```bash
docker-compose down
docker-compose up -d
```

## Ports Exposed

* `5060` TCP/UDP: SIP
* `5080` TCP/UDP: SIP alternative
* `8021` TCP: Event Socket

## Notes

* FreeSWITCH runs as a non-root user inside the container.
* Make sure `mod_event_socket` is loaded for the event socket to work.
