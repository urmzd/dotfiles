#!/usr/bin/env zsh

queryinstallpackage "default-jre" 1
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
queryinstallpackage "maven"
