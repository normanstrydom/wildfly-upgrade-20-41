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

Remove-Item Env:\WILDFLY_PASSWORD





docker build -t wildfly-dual .


docker build -t wildfly-dual . 

docker exec -it aaa bash


/server-group=your-server-group:write-attribute(name=socket-binding-port-offset, value=1000)

/socket-binding-group=standard-sockets:write-attribute(name=port-offset, value=1000)


       <management-interfaces>
            <http-interface http-authentication-factory="management-http-authentication">
                <http-upgrade enabled="true" sasl-authentication-factory="management-sasl-authentication"/>
                <socket interface="management" port="${jboss.management.http.port:19990}"/>
            </http-interface>
        </management-interfaces>
    </management>

how would I use cli command at /soa/servers/wf41/bin/jboss-cli.sh to connect on localhost port 19990 and execute command /socket-binding-group=standard-sockets:write-attribute(name=port-offset, value=1000)

/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/socket-binding-group=standard-sockets:write-attribute(name=port-offset, value=1000)"

/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=master/server-config=server-one:write-attribute(name=port-offset, value=1000)"

/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-one:write-attribute(name=socket-binding-port-offset, value=1000)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-two:write-attribute(name=socket-binding-port-offset, value=1150)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-three:write-attribute(name=socket-binding-port-offset, value=1250)"



#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk21
export PATH=$JAVA_HOME/bin:$PATH

# 1. Start WildFly Domain in the background
/soa/servers/wf41/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0 -Djboss.management.http.port=19990 &

# 2. Wait until the management interface is up and running
echo "Waiting for WildFly Domain controller to start on port 19990..."
until /soa/servers/wf41/bin/jboss-cli.sh --controller=localhost:19990 --connect --command=":read-attribute(name=process-type)" &>/dev/null; do
    sleep 2
done
echo "WildFly has started! Executing commands..."

# 3. Execute CLI commands
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-one:write-attribute(name=socket-binding-port-offset, value=1000)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-two:write-attribute(name=socket-binding-port-offset, value=1150)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-three:write-attribute(name=socket-binding-port-offset, value=1250)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary:reload"

# 4. Bring the background domain process back to the foreground so the script doesn't exit immediately
wait


Remove-Item Env:\WILDFLY_PASSWORD

/server-group=my-new-group:add(profile=full, socket-binding-group=full-sockets)
/host=master/server-config=my-server-instance:add(group=my-new-group, auto-start=true, socket-binding-port-offset=100)
/host=master/server-config=my-server-instance:stop
/host=master/server-config=my-server-instance:remove
/server-group=my-new-group:remove
