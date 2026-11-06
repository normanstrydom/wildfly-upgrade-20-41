FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# USER root

RUN mkdir -p /soa/downloads /soa/servers/wf21 /soa/servers/wf41 /soa/jdk/jdk11 /soa/jdk/jdk21

COPY openlogic-openjdk-11.0.32+9-linux-x64.tar.gz /soa/downloads/
COPY openlogic-openjdk-21.0.12+8-linux-x64.tar.gz /soa/downloads/
COPY wildfly-21.0.1.Final.tar.gz /soa/downloads/
COPY wildfly-41.0.1.Final.tar.gz /soa/downloads/

RUN tar -xzf /soa/downloads/openlogic-openjdk-11.0.32+9-linux-x64.tar.gz -C /soa/jdk/jdk11 --strip-components=1
RUN tar -xzf /soa/downloads/openlogic-openjdk-21.0.12+8-linux-x64.tar.gz -C /soa/jdk/jdk21 --strip-components=1
RUN tar -xzf /soa/downloads/wildfly-21.0.1.Final.tar.gz -C /soa/servers/wf21 --strip-components=1
RUN tar -xzf /soa/downloads/wildfly-41.0.1.Final.tar.gz -C /soa/servers/wf41 --strip-components=1

RUN useradd -m -s /bin/bash wildfly \
    && chown -R wildfly:wildfly /soa/servers /soa/jdk /soa/downloads

CMD ["tail", "-f", "/dev/null"]


