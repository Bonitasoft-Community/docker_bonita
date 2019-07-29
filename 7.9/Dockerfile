FROM ubuntu:18.04

MAINTAINER Jérémy Jacquier-Roux <jeremy.jacquier-roux@bonitasoft.org>

# install packages
RUN apt-get update && apt-get install -y \
  curl \
  gnupg2 \
  mysql-client-core-5.7 \
  openjdk-11-jre-headless \
  postgresql-client \
  unzip \
  zip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/custom-init.d/

# create user to launch Bonita as non-root
RUN groupadd -r bonita -g 1000 \
  && useradd -u 1000 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita

# grab gosu
RUN (gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  || gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4) \
  && curl -fsSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu \
  && curl -fsSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" -o /usr/local/bin/gosu.asc \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

# use --build-arg key=value in docker build command to override arguments
ARG BONITA_VERSION
ARG BONITA_SHA256
ARG BONITA_URL

ENV BONITA_VERSION ${BONITA_VERSION:-7.9.2}
ENV BONITA_SHA256  ${BONITA_SHA256:-98bc66a259d82f46732bfdd96c6eb75b34f96def9ad519b4f991e6fccfc2b121}
ENV BONITA_URL ${BONITA_URL:-https://release.ow2.org/bonita/BonitaCommunity-${BONITA_VERSION}-tomcat.zip}

# add Bonita archive to the container
RUN mkdir /opt/files \
  && curl -fsSL ${BONITA_URL} -o /opt/files/BonitaCommunity-${BONITA_VERSION}-tomcat.zip

# display downloaded checksum
RUN sha256sum /opt/files/BonitaCommunity-${BONITA_VERSION}-tomcat.zip

# check with expected checksum
RUN echo "$BONITA_SHA256" /opt/files/BonitaCommunity-${BONITA_VERSION}-tomcat.zip | sha256sum -c -

# create Volume to store Bonita files
VOLUME /opt/bonita

COPY files /opt/files
COPY templates /opt/templates

# expose Tomcat port
EXPOSE 8080

# command to run when the container starts
CMD ["/opt/files/startup.sh"]
