# FreeSWITCH Docker Setup

This repository contains a Docker setup for FreeSWITCH 1.10.11 on Ubuntu 22.04.

## Requirements

- Docker
- Docker Compose

## How to Run

1. **Clone the repository**:

```bash
https://github.com/humayun2000444/Voicechnager_docker.git
cd Voicechnager_docker
```

2. **Build and start the container**:

```bash
docker-compose up --build -d
```

3. **Check container logs**:

```bash
docker logs -f freeswitch
```

## Configure Event Socket

1. Enter the container:

```bash
docker exec -it freeswitch /bin/bash
```


2. For restarting FreeSWITCH the container:

```bash
docker-compose down
docker-compose up -d
```

3. **Connect to FreeSWITCH CLI**:

```bash
docker exec -it freeswitch fs_cli
```

4. **Stop the container**:

```bash
docker-compose down
```

## Ports Exposed

* `5060` TCP/UDP: SIP
* `5080` TCP/UDP: SIP alternative
* `8021` TCP: Event Socket
* `8080` ESL Client

## Notes

* FreeSWITCH runs as a non-root user inside the container.
