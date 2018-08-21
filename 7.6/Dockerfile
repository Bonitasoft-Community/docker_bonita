FROM ubuntu:16.04

MAINTAINER Jérémy Jacquier-Roux <jeremy.jacquier-roux@bonitasoft.org>

# install packages
RUN apt-get update && apt-get install -y \
  mysql-client-core-5.7 \
  openjdk-8-jre-headless \
  postgresql-client \
  unzip \
  curl \
  zip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/custom-init.d/

# create user to launch Bonita as non-root
RUN groupadd -r bonita -g 1000 \
  && useradd -u 1000 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita

# grab gosu
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -fsSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu \
  && curl -fsSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" -o /usr/local/bin/gosu.asc \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

# use --build-arg key=value in docker build command to override arguments
ARG BONITA_VERSION
ARG TOMCAT_VERSION
ARG BONITA_SHA256
ARG BONITA_URL

ENV BONITA_VERSION ${BONITA_VERSION:-7.6.3}
ENV TOMCAT_VERSION ${TOMCAT_VERSION:-8.5.23}
ENV BONITA_SHA256  ${BONITA_SHA256:-54c6ed105b31a216a7db513bc16abc06f8c003ea9223329285a410158e8c52fc}
ENV BONITA_URL ${BONITA_URL:-https://download.forge.ow2.org/bonita/BonitaCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip}

# add Bonita archive to the container
RUN mkdir /opt/files \
  && curl -fsSL ${BONITA_URL} -o /opt/files/BonitaCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip

# display downloaded checksum
RUN sha256sum /opt/files/BonitaCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip

# check with expected checksum
RUN echo "$BONITA_SHA256" /opt/files/BonitaCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip | sha256sum -c -

# create Volume to store Bonita files
VOLUME /opt/bonita

COPY files /opt/files
COPY templates /opt/templates

# expose Tomcat port
EXPOSE 8080

# command to run when the container starts
CMD ["/opt/files/startup.sh"]
