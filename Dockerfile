FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Install dependencies
RUN apt-get update && apt-get install -y \
  build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev \
  libsqlite3-dev libcurl4-openssl-dev libpcre3-dev libspeexdsp-dev libldns-dev \
  libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip libavformat-dev \
  libswscale-dev liblua5.2-dev liblua5.2-0 cmake libpq-dev unixodbc-dev autoconf \
  automake ntpdate libxml2-dev libpq-dev libpq5 sngrep lua5.2 lua5.2-doc \
  libreadline-dev git wget tar && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/src

# Step 2: Install spandsp
RUN git clone https://github.com/freeswitch/spandsp.git && \
    cd spandsp && \
    git checkout 0d2e6ac && \
    ./bootstrap.sh && ./configure && make && make install

# Step 3: Install sofia-sip
RUN wget "https://github.com/freeswitch/sofia-sip/archive/master.tar.gz" -O sofia-sip.tar.gz && \
    tar -xvf sofia-sip.tar.gz && \
    cd sofia-sip-master && \
    ./bootstrap.sh && ./configure && make && make install

# Step 3b: Update linker for both spandsp and sofia-sip
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local-libs.conf && \
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local-libs.conf && \
    ldconfig

# Step 4: Download FreeSWITCH 1.10.11 source
RUN wget https://files.freeswitch.org/releases/freeswitch/freeswitch-1.10.11.-release.tar.gz && \
    tar -zxvf freeswitch-1.10.11.-release.tar.gz

# Step 5: Install Lua module
RUN cp /usr/include/lua5.2/*.h /usr/local/src/freeswitch-1.10.11.-release/src/mod/languages/mod_lua/ && \
    ln -s /usr/lib/x86_64-linux-gnu/liblua5.2.so /usr/lib/x86_64-linux-gnu/liblua.so

# Step 6–7: Configure and compile FreeSWITCH
WORKDIR /usr/local/src/freeswitch-1.10.11.-release
RUN sed -i '/mod_signalwire/s/^/#/' modules.conf && \
    sed -i '/mod_verto/s/^/#/' modules.conf && \
    ./configure --enable-core-odbc-support --enable-core-pgsql-support && \
    make && make install && make cd-sounds-install

# Step 8: Symlinks and minimal permissions fix
RUN mkdir -p /usr/local/freeswitch/run && \
    groupadd -f freeswitch && \
    id -u freeswitch || adduser --quiet --system --home /usr/local/freeswitch \
        --gecos 'FreeSWITCH open source softswitch' --ingroup freeswitch freeswitch --disabled-password && \
    chown -R freeswitch:freeswitch /usr/local/freeswitch && \
    chmod -R ug=rwX,o= /usr/local/freeswitch && \
    chmod -R u=rwx,g=rx /usr/local/freeswitch/bin && \
    ln -sf /usr/local/freeswitch/conf /etc/freeswitch && \
    ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli && \
    ln -sf /usr/local/freeswitch/bin/freeswitch /usr/sbin/freeswitch
RUN apt-get update && apt-get install -y iproute2 net-tools && rm -rf /var/lib/apt/lists/*

# Expose SIP & Event Socket
EXPOSE 5060/udp 5060/tcp 5080/udp 5080/tcp 8021/tcp

# Run FreeSWITCH as non-root, load full configs
USER freeswitch
CMD ["/usr/sbin/freeswitch", "-u", "freeswitch", "-g", "freeswitch", "-nonat"]
