FROM node:8.9-slim@sha256:8233daae003ba0ecba4e6d70cab8525c30a3f085935afc624a275892ebe23f7c

RUN printf '%s\n' \
    'deb [trusted=yes check-valid-until=no] http://archive.debian.org/debian jessie main' \
    'deb [trusted=yes check-valid-until=no] http://archive.debian.org/debian-security jessie/updates main' \
    > /etc/apt/sources.list \
    && printf '%s\n' \
      'Acquire::Check-Valid-Until "false";' \
      'Acquire::AllowInsecureRepositories "true";' \
      'Acquire::AllowDowngradeToInsecureRepositories "true";' \
      > /etc/apt/apt.conf.d/99legacy-jessie \
    && apt-get update -qq \
    && apt-get install -qy --allow-unauthenticated --no-install-recommends \
      bzip2 \
      ca-certificates \
      curl \
      libfontconfig \
    && rm -rf /var/lib/apt/lists/*

RUN yarn global add phantomjs-prebuilt

ADD . /app
WORKDIR /app

CMD ["/app/tests.sh"]