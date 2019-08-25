FROM eientei/iqdb:latest as iqdb
FROM eientei/iqdb-query:latest as iqdb-query
FROM ruby:2.5-stretch
ENV \
  MB_DATABASE_URL=postgres://user:pass@somehost:5432/dbname \
  MB_MEMCACHE_SERVERS=somehost:11211 \
  MB_APP_NAME=iibooru \
  MB_HOST_NAME=localhost \
  MB_URL_BASE=http://127.0.0.1:8080 \
  MB_ADMIN_CONTACT=foobar@example.com \
  MB_IQDB_XML_URL=http://iqdb:8080/iqdb-xml.php \
  LISTEN_ADDR=:8082 \
  IQDB_ADDR=127.0.0.1:5566 \
  SERVICE_NAME=iibooru
RUN \
  cd / && \
  apt-get update && \
  apt-get install -y \
    netcat-openbsd \
    build-essential \
    libmagick++-dev \
    jhead \
    libxslt1-dev \
    libyaml-dev \
    libssl-dev \
    libpcre3-dev \
    libpq-dev \
    postgresql-server-dev-9.6 \
    postgresql-client-9.6 \
    libreadline-dev && \
  apt-get install -y \
    libssl1.0-dev \
    nodejs-dev
COPY . /moebooru
RUN cd /moebooru && \
  bundle install && \
  mv config config_tmpl && \
  mkdir -p config
COPY --from=iqdb /iqdb /
COPY --from=iqdb-query /iqdb-query /
COPY ./docker/entrypoint.sh /
COPY ./docker/iqdb-script.sh /
ENTRYPOINT ["/entrypoint.sh"]
