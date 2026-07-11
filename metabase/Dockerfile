#This Dockerfile mounts the certs
FROM eclipse-temurin:25-jammy
WORKDIR /app
COPY ojdbc8-full /app/plugins/
ARG METABASE_VERSION
ENV METABASE_VER=$METABASE_VERSION
ENV FC_LANG=en-US \
    LC_CTYPE=en_US.UTF-8

# RELAX SECURITY: enable legacy TLS versions/algorithms (e.g. TLS 1.0/1.1, SHA1, DH/RSA keys < 2048)
# so Metabase can complete a TLS handshake with the Oracle DB's legacy 1024-bit RSA cert
# (imported into cacerts at runtime by run_app.sh). Newer JDKs disable these by default.
RUN sed -i '/^jdk.tls.disabledAlgorithms=/,/[^\\]$/c\jdk.tls.disabledAlgorithms=SSLv3' "$JAVA_HOME/conf/security/java.security"

# packages for your application
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl wget \
    && rm -rf /var/lib/apt/lists/*
RUN wget -q https://downloads.metabase.com/${METABASE_VER}/metabase.jar \
    && chmod -R 777 /app
RUN chmod -R 777 /opt && chmod -R 777 /etc/ca-certificates && chmod -R 777 "${JAVA_HOME}"/lib/security

EXPOSE 3000
USER 185
COPY --chmod=755 run_app.sh /app/run_app.sh
ENTRYPOINT ["/app/run_app.sh"]
