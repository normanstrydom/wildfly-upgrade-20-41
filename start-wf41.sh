#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk21
export PATH=$JAVA_HOME/bin:$PATH
/soa/servers/wf41/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0 -Djboss.management.http.port=11990 2>&1 &

echo "Waiting for WildFly Domain controller to start on port 11990..."
until /soa/servers/wf41/bin/jboss-cli.sh --controller=localhost:11990 --connect --command=":read-attribute(name=process-type)" &>/dev/null; do
    sleep 2
done
echo "WildFly has started! Executing commands..."

/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=server-one:write-attribute(name=socket-binding-port-offset, value=2150)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=server-two:write-attribute(name=socket-binding-port-offset, value=2300)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=server-three:remove"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/server-group=other-server-group:remove"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/server-group=load-balancer-server-group:add(profile=load-balancer, socket-binding-group=load-balancer-sockets)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=load-balancer:add(group=load-balancer-server-group, auto-start=true, socket-binding-port-offset=2000)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/server-group=full-ha-server-group:add(profile=full-ha, socket-binding-group=full-ha-sockets)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=server-ha-01:add(group=full-ha-server-group, auto-start=true, socket-binding-port-offset=2450)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=server-ha-02:add(group=full-ha-server-group, auto-start=true, socket-binding-port-offset=2600)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary/server-config=server-ha-03:add(group=full-ha-server-group, auto-start=true, socket-binding-port-offset=2750)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:11990 --command="/host=primary:reload"


