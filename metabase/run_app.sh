#!/bin/bash
echo "$CMAN_CERT"
echo "$CMAN_CERT" >> /opt/cman.crt
keytool -import -alias "cman-certs"  -keystore "${JAVA_HOME}"/lib/security/cacerts -file /opt/cman.crt -storepass changeit  -noprompt || exit 1
echo "Starting Metabase"
java -jar metabase.jar
