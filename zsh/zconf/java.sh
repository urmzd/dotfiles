#!/usr/bin/env zsh

export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")