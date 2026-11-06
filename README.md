#

FROM ubuntu:22.04

# Install tools
RUN apt-get update && apt-get install -y wget unzip curl && rm -rf /var/lib/apt/lists/*

# Install JDK 11 (for WildFly 20) and JDK 21 (for WildFly 41)
RUN apt-get update && apt-get install -y openjdk-11-jdk openjdk-21-jdk

WORKDIR /opt

# Download WildFly 20
RUN wget https://jboss.org && \
    unzip wildfly-20.0.1.Final.zip && mv wildfly-20.0.1.Final wildfly-20 && rm wildfly-20.0.1.Final.zip

# Download WildFly 41
RUN wget https://jboss.org && \
    unzip wildfly-41.0.0.Final.zip && mv wildfly-41.0.0.Final wildfly-41 && rm wildfly-41.0.0.Final.zip

# Create Entrypoint
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

EXPOSE 8080 9990 8180 10090
ENTRYPOINT ["/opt/entrypoint.sh"]





docker build -t wildfly-dual .


docker build -t wildfly-dual . 

docker exec -it aaa bash


