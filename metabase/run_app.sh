#!/bin/bash
DB_HOST_PORT_LIST=nrcdb01.bcgov:1543,nrcdb03.bcgov:1543,nrkdb01.bcgov:1543,nrkdb03.bcgov:1543
echo "Adding certs"
  IFS=','
  read -ra DB_HOST_PORT_ARRAY <<< "${DB_HOST_PORT_LIST}"
  for DB_HOST_PORT in "${DB_HOST_PORT_ARRAY[@]}"; do
    IFS=':'
    read -ra strarr <<<"${DB_HOST_PORT}"
    DB_HOST="${strarr[0]}"
    echo "DB_HOST is $DB_HOST"
    DB_PORT="${strarr[1]}"
    echo "DB_PORT is $DB_PORT"
    echo "I will try to get the ${DB_HOST}-1 cert"
    echo "Connecting to ${DB_HOST}:${DB_PORT}"
    java InstallCert --quiet "${DB_HOST}:${DB_PORT}"
    keytool -exportcert -alias "$DB_HOST-1" -keystore jssecacerts -storepass changeit -file /opt/"$DB_HOST-1.cer"
    keytool -importcert -alias "orakey-$DB_HOST-1" -noprompt -keystore "${JAVA_HOME}"/lib/security/cacerts -storepass changeit -file /opt/"$DB_HOST-1.cer"
  done

echo "Starting Metabase"
java -Dlog4j.configurationFile=file:/opt/log4j2.xml -jar metabase.jar
