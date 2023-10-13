#This Dockerfile mounts the certs
FROM docker.io/openjdk:21-jdk-slim-bullseye
WORKDIR /app
COPY ojdbc8-full /app/plugins/
ARG METABASE_VERSION=v0.47.2
ENV METABASE_VER=$METABASE_VERSION
ENV FC_LANG=en-US \
  LC_CTYPE=en_US.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends \
# packages for your application
bash curl wget \
&& rm -rf /var/lib/apt/lists/*
RUN wget -q https://downloads.metabase.com/${METABASE_VER}/metabase.jar \
&& chmod -R 777 /app
COPY InstallCert.class .
COPY "InstallCert\$SavingTrustManager.class" .
COPY run_app.sh .
RUN chmod +x run_app.sh
RUN chmod -R 777 /opt && chmod -R 777 /etc/ca-certificates && chmod -R 777 "${JAVA_HOME}"/lib/security
EXPOSE 3000
USER 185
ENTRYPOINT ["./run_app.sh"]
