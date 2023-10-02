#!/bin/bash
cert_folder="/app/cert"
mkdir -p $cert_folder
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

    openssl s_client -connect "${DB_HOST}:${DB_PORT}" -showcerts </dev/null | openssl x509 -outform pem >"$cert_folder/${DB_HOST}.pem" || exit 1
    openssl x509 -outform der -in "$cert_folder/${DB_HOST}.pem" -out "$cert_folder/${DB_HOST}.der" || exit 1
    keytool -import -alias "${DB_HOST}" -keystore"${JAVA_HOME}"/lib/security/cacerts -file "$cert_folder/${DB_HOST}.der" -storepass changeit -noprompt || exit 1

    echo "Completed for $DB_HOST $DB_PORT."
    #echo adding certificates for "${DB_HOST}:${DB_PORT}"
    #java InstallCert --quiet "${DB_HOST}:${DB_PORT}"
    #keytool -exportcert -alias "$DB_HOST-1" -keystore jssecacerts -storepass changeit -file /opt/"$DB_HOST-1.cer"
    #keytool -importcert -alias "orakey-$DB_HOST-1" -noprompt -keystore "${JAVA_HOME}"/lib/security/cacerts -storepass changeit -file /opt/"$DB_HOST-1.cer"
  done

echo "Starting Metabase"
java -jar metabase.jar
