#!/bin/bash
cert_folder="/opt"
# Percentage of the container's memory *limit* (charts/nr-metabase
# values.yaml: metabase.resources.limits.memory), not a fixed size, so the
# heap scales automatically if that limit ever changes. 60% of the chart's limit
MIN_HEAP_PERCENT=${MIN_HEAP_PERCENT:-60}
MAX_HEAP_PERCENT=${MAX_HEAP_PERCENT:-60}

# Verify that the required environment variables are set
if [ -z "$DB_HOST_PORT_ENV" ]; then
  echo -e "\n---"
  echo -e "Warning: DB_HOST_PORT_ENV is not set. \n"

fi

IFS=','
read -ra DB_HOST_PORT_ARRAY <<< "${DB_HOST_PORT_ENV}"
for DB_HOST_PORT in "${DB_HOST_PORT_ARRAY[@]}"; do
  IFS=':'
  read -ra strarr <<<"${DB_HOST_PORT}"
  DB_HOST="${strarr[0]}"
  DB_PORT="${strarr[1]}"
  
  if [[ -z "$DB_HOST" || -z "$DB_PORT" ]]; then
    printf 'WARN: Skipping invalid entry "%s"\n' "$DB_HOST_PORT" >&2
    continue
  fi
  
  pem="$cert_folder/${DB_HOST}.pem"
  der="$cert_folder/${DB_HOST}.der"
  
  # Handshake and extract leaf cert to PEM
  if ! openssl s_client -servername "$DB_HOST" -connect "${DB_HOST}:${DB_PORT}" -showcerts </dev/null 2>/dev/null \
      | openssl x509 -outform pem >"$pem"; then
    printf 'WARN: TLS handshake or cert extraction failed for %s:%s\n' "$DB_HOST" "$DB_PORT" >&2
    continue
  fi

  # Convert PEM -> DER
  if ! openssl x509 -outform der -in "$pem" -out "$der"; then
    printf 'WARN: PEM->DER conversion failed for %s\n' "$DB_HOST" >&2
    continue
  fi

  # Import into Java cacerts
  if ! keytool -import -alias "orakey-${DB_HOST}-1" -keystore "${JAVA_HOME}/lib/security/cacerts" \
      -storepass changeit -file "$der" -noprompt; then
    printf 'WARN: keytool import failed for %s\n' "$DB_HOST" >&2
    continue
  fi

  printf 'INFO: Imported cert for %s:%s\n' "$DB_HOST" "$DB_PORT"
done

echo "NR Metabase started at: $(date +'%Y-%m-%d %H:%M:%S') with version: ${NR_MB_VERSION}"

# JDK 25 based tuning
JAVA_OPTS=(
  -Duser.name=metabase
  -XX:InitialRAMPercentage=${MIN_HEAP_PERCENT}
  -XX:MaxRAMPercentage=${MAX_HEAP_PERCENT}
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=200
  -XX:+UseCompactObjectHeaders
  -XX:MaxMetaspaceSize=400m
  -XX:+ExitOnOutOfMemoryError
)

if [ -f /config/log4j2.xml ]; then
  JAVA_OPTS+=(-Dlog4j.configurationFile=file:/config/log4j2.xml)
fi

java "${JAVA_OPTS[@]}" -jar metabase.jar