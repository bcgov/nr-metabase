#!/bin/bash
cert_folder="/opt"
MAX_HEAP=${MAX_HEAP:-750m}
MIN_HEAP=${MIN_HEAP:-750m}

# Verify that the required environment variables are set
if [ -z "$DB_HOST_PORT_ENV" ]; then
  echo "DB_HOST_PORT_ENV is not set.  Exiting."
  exit 1
fi
echo "DB_HOST_PORT_ENV is $DB_HOST_PORT_ENV"

IFS=','
read -ra DB_HOST_PORT_ARRAY <<< "${DB_HOST_PORT_ENV}"
for DB_HOST_PORT in "${DB_HOST_PORT_ARRAY[@]}"; do
  IFS=':'
  read -ra strarr <<<"${DB_HOST_PORT}"
  DB_HOST="${strarr[0]}"
  DB_PORT="${strarr[1]}"
  openssl s_client -connect "${DB_HOST}:${DB_PORT}" -showcerts </dev/null | openssl x509 -outform pem >"$cert_folder/${DB_HOST}.pem" || exit 1
  openssl x509 -outform der -in "$cert_folder/${DB_HOST}.pem" -out "$cert_folder/${DB_HOST}.der" || exit 1
  keytool -import -alias "orakey-${DB_HOST}-1" -keystore "${JAVA_HOME}"/lib/security/cacerts -storepass changeit -file "$cert_folder/${DB_HOST}.der" -noprompt || exit 1
done

echo -e "\033[1;33m=====================================\033[0m" # Bright Yellow
echo -e "\033[0;36m  _   _ ____      __  __ ____  \033[0m" # Cyan
echo -e "\033[0;36m | \ | |  _ \     |  \/  | __ ) \033[0m" # Cyan
echo -e "\033[0;36m |  \| | |_) |    | |\/| |  _ \ \033[0m" # Cyan
echo -e "\033[0;36m | |\  |  _ <     | |  | | |_) |\033[0m" # Cyan
echo -e "\033[0;36m |_| \_|_| \_\    |_|  |_|____/ \033[0m" # Cyan
echo -e "\033[0;36m                        ${NR_MB_VERSION} \033[0m" # Cyan
echo -e "\033[1;33m=====================================\033[0m" # Bright Yellow

if [ -f /mnt/conf/log4j2.xml ]; then
  java -Duser.name=metabase "-Xms${MIN_HEAP}" "-Xmx${MAX_HEAP}" -XX:TieredStopAtLevel=2 -XX:+UseZGC  -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=350m -XX:ParallelGCThreads=2 -Djava.util.concurrent.ForkJoinPool.common.parallelism=4 -XX:CICompilerCount=2 -XX:+ExitOnOutOfMemoryError -Dlog4j.configurationFile=file:/config/log4j2.xml -jar metabase.jar
else
  java -Duser.name=metabase "-Xms${MIN_HEAP}" "-Xmx${MAX_HEAP}" -XX:TieredStopAtLevel=2 -XX:+UseZGC  -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=350m -XX:ParallelGCThreads=2 -Djava.util.concurrent.ForkJoinPool.common.parallelism=4 -XX:CICompilerCount=2 -XX:+ExitOnOutOfMemoryError -jar metabase.jar
fi

