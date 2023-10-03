#This Dockerfile mounts the certs
FROM docker.io/openjdk:17-alpine
WORKDIR /app
COPY ojdbc8-full /app/plugins/
ARG METABASE_VERSION
ENV METABASE_VER=$METABASE_VERSION
ENV FC_LANG=en-US \
  LC_CTYPE=en_US.UTF-8
RUN apk add --update --no-cache bash curl wget ttf-dejavu fontconfig
RUN wget -q https://downloads.metabase.com/${METABASE_VER}/metabase.jar \
&& chmod -R 777 /app
COPY InstallCert.class .
COPY "InstallCert\$SavingTrustManager.class" .
COPY run_app.sh .
RUN chmod +x run_app.sh
RUN chmod -R 777 /opt
EXPOSE 3000
USER 185
ENTRYPOINT ["./run_app.sh"]
