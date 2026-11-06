#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk11
export PATH=$JAVA_HOME/bin:$PATH
/soa/servers/wf20/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0