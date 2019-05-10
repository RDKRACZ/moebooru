
FROM ruby:2.5
COPY ./entrypoint.sh /
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
    nodejs-dev && \
  git clone https://github.com/eientei/moebooru && \
  cd moebooru && \
  bundle install && \
  mv config config_tmpl && \
  mkdir -p config
ENV \
  MB_DATABASE_URL=postgres://user:pass@somehost:5432/dbname \
  MB_MEMCACHE_SERVERS=somehost:11211
ENTRYPOINT ["/entrypoint.sh"]
