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

# create user to launch Bonita BPM as non-root
RUN groupadd -r bonita -g 1000 \
  && useradd -u 1000 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita

# grab gosu
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -sSL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu \
  && curl -sSL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture).asc" -o /usr/local/bin/gosu.asc \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

# use --build-arg key=value in docker build command to override arguments
ARG BONITA_VERSION
ARG TOMCAT_VERSION
ARG BONITA_SHA256
ARG BONITA_URL

ENV BONITA_VERSION ${BONITA_VERSION:-7.5.4}
ENV TOMCAT_VERSION ${TOMCAT_VERSION:-7.0.76}
ENV BONITA_SHA256  ${BONITA_SHA256:-b7ccec231d9083b1b532b0aeaa4de3d38d91cae12df1725f8a802be5be170d21}
ENV BONITA_URL ${BONITA_URL:-https://download.forge.ow2.org/bonita/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip}

# add Bonita BPM archive to the container
RUN mkdir /opt/files \
  && curl -sSL ${BONITA_URL} -o /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip

# display downloaded checksum
RUN sha256sum /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip

# check with expected checksum
RUN echo "$BONITA_SHA256" /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip | sha256sum -c -

# create Volume to store Bonita BPM files
VOLUME /opt/bonita

COPY files /opt/files
COPY templates /opt/templates

# expose Tomcat port
EXPOSE 8080

# command to run when the container starts
CMD ["/opt/files/startup.sh"]
