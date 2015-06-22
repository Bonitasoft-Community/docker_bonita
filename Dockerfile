FROM ubuntu:14.04

MAINTAINER Jérémy Jacquier-Roux <jeremy.jacquier-roux@bonitasoft.org>

ENV BONITA_VERSION 7.0.0
ENV TOMCAT_VERSION 7.0.55
ENV BONITA_ARCHIVE_DIR BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}
ENV BONITA_ARCHIVE_FILE ${BONITA_ARCHIVE_DIR}.zip
ENV BONITA_DOWNLOAD_SHA256 6eba7a2f513a455ada897a177117aa06b47c0fe8f79254891d0b5bd21116c423
ENV BASE_URL http://download.forge.ow2.org/bonita
ENV POSTGRES_JDBC_DRIVER_FILE postgresql-9.3-1102.jdbc41.jar
ENV POSTGRES_JDBC_DRIVER_URL https://jdbc.postgresql.org/download/${POSTGRES_JDBC_DRIVER_FILE}
ENV MYSQL_JDBC_DRIVER_NAME mysql-connector-java-5.1.26
ENV MYSQL_JDBC_DRIVER_URL http://dev.mysql.com/get/Downloads/Connector-J/${MYSQL_JDBC_DRIVER_NAME}.zip
ENV MYSQL_JDBC_DRIVER_FILE ${MYSQL_JDBC_DRIVER_NAME}-bin.jar

# avoid debconf messages
ENV DEBIAN_FRONTEND noninteractive

# install packages
RUN apt-get update && apt-get install -y \
  mysql-client-core-5.5 \
  openjdk-7-jre-headless \
  postgresql-client \
  unzip \
  wget \
  zip \
  && rm -rf /var/lib/apt/lists/*

COPY files /opt/files
COPY templates /opt/templates

# retrieve JDBC drivers
ADD ${POSTGRES_JDBC_DRIVER_URL} /opt/files/
RUN wget -q ${MYSQL_JDBC_DRIVER_URL} -O /opt/files/${MYSQL_JDBC_DRIVER_NAME}.zip \
  && unzip -q /opt/files/${MYSQL_JDBC_DRIVER_NAME}.zip -d /opt/files/ \
  && mv /opt/files/${MYSQL_JDBC_DRIVER_NAME}/${MYSQL_JDBC_DRIVER_FILE} /opt/files/ \
  && rm -r /opt/files/${MYSQL_JDBC_DRIVER_NAME} \
  && rm /opt/files/${MYSQL_JDBC_DRIVER_NAME}.zip

# add Bonita BPM archive to the container
RUN wget -q ${BASE_URL}/${BONITA_ARCHIVE_FILE} -O /opt/files/${BONITA_ARCHIVE_FILE} \
  &&  echo "$BONITA_DOWNLOAD_SHA256" /opt/files/${BONITA_ARCHIVE_FILE} | sha256sum -c -

# create Volume to store Bonita BPM files
VOLUME /opt/bonita

# create user to launch Bonita BPM as non-root
RUN groupadd -r bonita -g 222 \
  && useradd -u 222 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita

# expose Tomcat port
EXPOSE 8080

# command to run when the container starts
CMD ["/opt/files/startup.sh"]
