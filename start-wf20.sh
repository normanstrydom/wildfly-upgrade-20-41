#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk11
export PATH=$JAVA_HOME/bin:$PATH
/soa/servers/wf20/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0 2>&1 &

echo "Waiting for WildFly Domain controller to start on port 9990..."
until /soa/servers/wf20/bin/jboss-cli.sh --controller=localhost:9990 --connect --command=":read-attribute(name=process-type)" &>/dev/null; do
    sleep 2
    echo "Waiting for WildFly Domain controller to be ready..."
done
echo "WildFly has started! Executing commands..."
sleep 15

/soa/servers/wf20/bin/jboss-cli.sh --connect --controller=localhost:9990 --file=/soa/wf20.cli



