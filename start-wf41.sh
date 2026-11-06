#!/bin/bash

export JAVA_HOME=/soa/jdk/jdk21
export PATH=$JAVA_HOME/bin:$PATH
/soa/servers/wf41/bin/domain.sh -b 0.0.0.0