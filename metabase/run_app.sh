#!/bin/bash
cert_folder="/opt"
# Percentage of the container's memory *limit* (charts/nr-metabase
# values.yaml: metabase.resources.limits.memory), not a fixed size, so the
# heap scales automatically if that limit ever changes. 60% of the chart's
# current 1250Mi limit is 750Mi -- the same fixed heap this replaces.
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

# JDK 25 (see Dockerfile: eclipse-temurin:25-jammy) tuning.
#
# -server, -XX:TieredStopAtLevel=4 and the old -XX:CICompilerCount / GC
# thread-count pins are gone: -server is a no-op on any 64-bit JDK since 9,
# level 4 is already tiered compilation's default stop level, and pinning
# thread counts to a number picked for one container blocks the JVM's
# container-aware ergonomics (on by default) from sizing compiler/GC/
# ForkJoinPool threads to whatever CPU share the pod actually gets. Note
# this pod currently sets a CPU *request* (250m) but no *limit*, so those
# ergonomics fall back to the node's full core count; add
# resources.limits.cpu in values.yaml if that headroom needs bounding.
#
# Parallel GC is replaced with G1 (JDK 25's own default -- kept explicit so
# the choice reads as deliberate) because Metabase is a latency-sensitive
# dashboard/query UI, not a throughput batch job. MaxGCPauseMillis=200
# states that pause-time goal explicitly; it matches G1's own default and
# is a starting point to tighten once there's pause-time data to tune from.
#
# UseCompactObjectHeaders (JEP 519) is a stable product feature as of JDK 25
# (no longer needs -XX:+UnlockExperimentalVMOptions) that shrinks every
# object header from 12-16 bytes to 8, worth having given the container's
# modest memory footprint.
#
# InitialRAMPercentage/MaxRAMPercentage replace fixed -Xms/-Xmx: they compute
# off the container's cgroup memory *limit* (JVM container support is on by
# default), so the heap scales with whatever limit is deployed instead of a
# value baked into this script. This requires metabase.resources.limits.memory
# to actually be set in values.yaml -- confirmed locally that with no limit,
# these flags fall back to the *host's* total RAM, not the pod's, which is
# worse than the fixed heap they replace. -Xms/-Xmx must not be reintroduced
# alongside these: whichever is given last on the command line wins outright,
# it's not a merge.
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