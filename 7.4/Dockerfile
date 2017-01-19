FROM ubuntu:14.04

MAINTAINER Jérémy Jacquier-Roux <jeremy.jacquier-roux@bonitasoft.org>

# install packages
RUN apt-get update && apt-get install -y \
  mysql-client-core-5.5 \
  openjdk-7-jre-headless \
  postgresql-client \
  unzip \
  wget \
  zip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/custom-init.d/

# create user to launch Bonita BPM as non-root
RUN groupadd -r bonita -g 1000 \
  && useradd -u 1000 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita

# grab gosu
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN wget -q "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture)" -O /usr/local/bin/gosu \
  && wget -q "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture).asc" -O /usr/local/bin/gosu.asc \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

ENV BONITA_VERSION 7.4.1
ENV TOMCAT_VERSION 7.0.67
ENV BONITA_SHA256 e299ae1b68f40699ec8607911967c614206c7e74d6ab36ea03d3f1de7e8109a3
ENV POSTGRES_JDBC_DRIVER postgresql-9.3-1102.jdbc41.jar
ENV POSTGRES_SHA256 b78749d536da75c382d0a71c717cde6850df64e16594676fc7cacb5a74541d66
ENV MYSQL_JDBC_DRIVER mysql-connector-java-5.1.26
ENV MYSQL_SHA256 40b2d49f6f2551cc7fa54552af806e8026bf8405f03342205852e57a3205a868

# retrieve JDBC drivers
RUN mkdir /opt/files \
  && wget -q https://jdbc.postgresql.org/download/${POSTGRES_JDBC_DRIVER} -O /opt/files/${POSTGRES_JDBC_DRIVER} \
  && echo "$POSTGRES_SHA256" /opt/files/${POSTGRES_JDBC_DRIVER} | sha256sum -c - \
  && wget -q http://dev.mysql.com/get/Downloads/Connector-J/${MYSQL_JDBC_DRIVER}.zip -O /opt/files/${MYSQL_JDBC_DRIVER}.zip \
  && echo "$MYSQL_SHA256" /opt/files/${MYSQL_JDBC_DRIVER}.zip | sha256sum -c - \
  && unzip -q /opt/files/${MYSQL_JDBC_DRIVER}.zip -d /opt/files/ \
  && mv /opt/files/${MYSQL_JDBC_DRIVER}/${MYSQL_JDBC_DRIVER}-bin.jar /opt/files/ \
  && rm -r /opt/files/${MYSQL_JDBC_DRIVER} \
  && rm /opt/files/${MYSQL_JDBC_DRIVER}.zip

# add Bonita BPM archive to the container
RUN wget -q http://download.forge.ow2.org/bonita/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip -O /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip \
  && echo "$BONITA_SHA256" /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip | sha256sum -c -

# create Volume to store Bonita BPM files
VOLUME /opt/bonita

COPY files /opt/files
COPY templates /opt/templates

# expose Tomcat port
EXPOSE 8080

# command to run when the container starts
CMD ["/opt/files/startup.sh"]
