
FROM ruby:2.5
ENV \
  MB_DATABASE_URL=postgres://user:pass@somehost:5432/dbname \
  MB_MEMCACHE_SERVERS=somehost:11211
RUN \
  cd / && \
  apt-get update && \
  apt-get install -y \
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
RUN git clone https://github.com/eientei/moebooru && \
  cd moebooru && \
  bundle install && \
  mv config config_tmpl && \
  mkdir -p config
COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
