#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk21
export PATH=$JAVA_HOME/bin:$PATH
/soa/servers/wf41/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0 -Djboss.management.http.port=19990 2>&1 &

echo "Waiting for WildFly Domain controller to start on port 19990..."
until /soa/servers/wf41/bin/jboss-cli.sh --controller=localhost:19990 --connect --command=":read-attribute(name=process-type)" &>/dev/null; do
    sleep 2
done
echo "WildFly has started! Executing commands..."

/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-one:write-attribute(name=socket-binding-port-offset, value=10000)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-two:write-attribute(name=socket-binding-port-offset, value=10150)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary/server-config=server-three:write-attribute(name=socket-binding-port-offset, value=10250)"
/soa/servers/wf41/bin/jboss-cli.sh --connect --controller=localhost:19990 --command="/host=primary:reload"
