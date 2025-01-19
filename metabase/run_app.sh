#!/bin/bash
DB_HOST_PORT_ENV=${DB_HOST_PORT_ENV}
cert_folder="/opt"
MAX_HEAP=${MAX_HEAP:-750m}
MIN_HEAP=${MIN_HEAP:-750m}
echo "DB_HOST_PORT_ENV is $DB_HOST_PORT_ENV"
if [ -z "$DB_HOST_PORT_ENV" ]; then
  DB_HOST_PORT_ENV=nrcdb01.bcgov:1543,nrcdb03.bcgov:1543,nrkdb01.bcgov:1543,nrkdb03.bcgov:1543,nrcdb02.bcgov:1543,nrkdb02.bcgov:1543
fi
echo "DB_HOST_PORT_ENV is $DB_HOST_PORT_ENV"
echo "Adding certs"
  IFS=','
  read -ra DB_HOST_PORT_ARRAY <<< "${DB_HOST_PORT_ENV}"
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
    keytool -import -alias "orakey-${DB_HOST}-1" -keystore "${JAVA_HOME}"/lib/security/cacerts -storepass changeit -file "$cert_folder/${DB_HOST}.der" -noprompt || exit 1
  done

echo -e "\033[1;33m=====================================\033[0m" # Bright Yellow
echo -e "\033[0;36m  _   _ ____    __  __ ____  \033[0m" # Cyan
echo -e "\033[0;36m | \ | |  _ \   |  \/  | __ ) \033[0m" # Cyan
echo -e "\033[0;36m |  \| | |_) |  | |\/| |  _ \ \033[0m" # Cyan
echo -e "\033[0;36m | |\  |  _ <   | |  | | |_) |\033[0m" # Cyan
echo -e "\033[0;36m |_| \_|_| \_\  |_|  |_|____/ \033[0m" # Cyan
echo -e "\033[0;36m                              \033[0m" # Cyan
echo -e "\033[1;33m=====================================\033[0m" # Bright Yellow

if [ -f /mnt/conf/log4j2.xml ]; then
  echo "/mnt/conf/log4j2.xml exists."
  java -Duser.name=metabase "-Xms${MIN_HEAP}" "-Xmx${MAX_HEAP}" -XX:TieredStopAtLevel=2 -XX:+UseZGC  -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=350m -XX:ParallelGCThreads=2 -Djava.util.concurrent.ForkJoinPool.common.parallelism=4 -XX:CICompilerCount=2 -XX:+ExitOnOutOfMemoryError -Dlog4j.configurationFile=file:/config/log4j2.xml -jar metabase.jar
else
  echo "/mnt/conf/log4j2.xml does not exist."
  java -Duser.name=metabase "-Xms${MIN_HEAP}" "-Xmx${MAX_HEAP}" -XX:TieredStopAtLevel=2 -XX:+UseZGC  -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=350m -XX:ParallelGCThreads=2 -Djava.util.concurrent.ForkJoinPool.common.parallelism=4 -XX:CICompilerCount=2 -XX:+ExitOnOutOfMemoryError -jar metabase.jar
fi

