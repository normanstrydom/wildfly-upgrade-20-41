#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk11
export PATH=$JAVA_HOME/bin:$PATH
/soa/servers/wf20/bin/add-user.sh -u $WILDFLY_USER -p $WILDFLY_PASSWORD