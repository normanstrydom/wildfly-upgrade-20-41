FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN apt-get update && apt-get install -y \
    wget \
    telnet \
    net-tools \
    dos2unix \
    vim-tiny \
    curl \
    less \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /soa/downloads /soa/servers/wf20 /soa/servers/wf41 /soa/jdk/jdk11 /soa/jdk/jdk21

COPY openlogic-openjdk-11.0.32+9-linux-x64.tar.gz /soa/downloads/
COPY openlogic-openjdk-21.0.12+8-linux-x64.tar.gz /soa/downloads/
COPY wildfly-20.0.1.Final.tar.gz /soa/downloads/
COPY wildfly-41.0.1.Final.tar.gz /soa/downloads/

RUN tar -xzf /soa/downloads/openlogic-openjdk-11.0.32+9-linux-x64.tar.gz -C /soa/jdk/jdk11 --strip-components=1
RUN tar -xzf /soa/downloads/openlogic-openjdk-21.0.12+8-linux-x64.tar.gz -C /soa/jdk/jdk21 --strip-components=1
RUN tar -xzf /soa/downloads/wildfly-20.0.1.Final.tar.gz -C /soa/servers/wf20 --strip-components=1
RUN tar -xzf /soa/downloads/wildfly-41.0.1.Final.tar.gz -C /soa/servers/wf41 --strip-components=1

COPY configure-wf20.sh /soa/
COPY start-wf20.sh /soa/
COPY configure-wf41.sh /soa/
COPY start-wf41.sh /soa/

RUN dos2unix /soa/start-wf20.sh \
    && dos2unix /soa/configure-wf20.sh \
    && dos2unix /soa/start-wf41.sh \
    && dos2unix /soa/configure-wf41.sh

RUN chmod +x /soa/start-wf20.sh
RUN chmod +x /soa/start-wf41.sh

EXPOSE 8080 9990
EXPOSE 18080 19990

CMD ["tail", "-f", "/dev/null"]
