FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /usr/local/src

# ---------------------------
# Base dependencies
# ---------------------------
RUN apt-get update && \
    apt-get install -y software-properties-common wget unzip git build-essential \
    pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
    libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev \
    libsndfile1-dev libavformat-dev libswscale-dev liblua5.2-dev liblua5.2-0 cmake \
    libpq-dev unixodbc-dev autoconf automake ntpdate libxml2-dev sngrep lua5.2 lua5.2-doc \
    libreadline-dev iproute2 net-tools curl screen tar && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------
# Install JDK 21
# ---------------------------
RUN mkdir -p /usr/lib/jvm && \
    wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz && \
    tar -xzf jdk-21_linux-x64_bin.tar.gz -C /opt/ && \
    ln -s /opt/jdk-21.0.8 /usr/lib/jvm/java-21-openjdk && \
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-openjdk/bin/java 1 && \
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-21-openjdk/bin/javac 1 && \
    update-alternatives --set java /usr/lib/jvm/java-21-openjdk/bin/java && \
    update-alternatives --set javac /usr/lib/jvm/java-21-openjdk/bin/javac && \
    java -version && javac -version


# ---------------------------
# Install Maven via apt
# ---------------------------
RUN apt-get update && \
    apt-get install -y maven && \
    mvn -v

# ---------------------------
# Install spandsp
# ---------------------------
RUN git clone https://github.com/freeswitch/spandsp.git && \
    cd spandsp && git checkout 0d2e6ac && \
    ./bootstrap.sh && ./configure && make && make install

# ---------------------------
# Install sofia-sip
# ---------------------------
RUN wget "https://github.com/freeswitch/sofia-sip/archive/master.tar.gz" -O sofia-sip.tar.gz && \
    tar -xvf sofia-sip.tar.gz && cd sofia-sip-master && \
    ./bootstrap.sh && ./configure && make && make install

# ---------------------------
# Update linker
# ---------------------------
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local-libs.conf && \
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local-libs.conf && ldconfig

# ---------------------------
# Install FreeSWITCH
# ---------------------------
RUN wget https://files.freeswitch.org/releases/freeswitch/freeswitch-1.10.11.-release.tar.gz && \
    tar -zxvf freeswitch-1.10.11.-release.tar.gz

# ---------------------------
# Lua module fix
# ---------------------------
RUN cp /usr/include/lua5.2/*.h /usr/local/src/freeswitch-1.10.11.-release/src/mod/languages/mod_lua/ && \
    ln -s /usr/lib/x86_64-linux-gnu/liblua5.2.so /usr/lib/x86_64-linux-gnu/liblua.so

# ---------------------------
# Compile FreeSWITCH
# ---------------------------
WORKDIR /usr/local/src/freeswitch-1.10.11.-release
RUN sed -i '/mod_signalwire/s/^/#/' modules.conf && \
    sed -i '/mod_verto/s/^/#/' modules.conf && \
    ./configure --enable-core-odbc-support --enable-core-pgsql-support && \
    make && make install && make cd-sounds-install

# ---------------------------
# Symlinks & permissions
# ---------------------------
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

# ---------------------------
# Install mod_voicechanger
# ---------------------------
RUN git clone https://github.com/humayun2000444/mod_voicechanger.git /usr/local/src/mod_voicechanger && \
    cd /usr/local/src/mod_voicechanger && git checkout multiple_voice && \
    mkdir build && cd build && cmake .. && make && make install && \
    cp mod_voicechanger.so /usr/local/freeswitch/mod/ && \
    chown freeswitch:freeswitch /usr/local/freeswitch/mod/mod_voicechanger.so

# ---------------------------
# Clone Spring Boot app
# ---------------------------
WORKDIR /usr/local/src
RUN git clone https://github.com/humayun2000444/VoicechnagerBackend.git
WORKDIR /usr/local/src/VoicechnagerBackend

# ---------------------------
# Build Spring Boot backend
# ---------------------------
RUN mvn clean package -DskipTests

# ---------------------------
# Expose ports
# ---------------------------
EXPOSE 5060/udp 5060/tcp 5080/udp 5080/tcp 8021/tcp 8080/tcp

# ---------------------------
# Copy entrypoint
# ---------------------------
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# ---------------------------
# Use FreeSWITCH user
# ---------------------------
USER freeswitch
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
