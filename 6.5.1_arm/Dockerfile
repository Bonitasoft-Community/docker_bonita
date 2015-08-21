FROM armbuild/ubuntu-debootstrap:trusty


MAINTAINER Jérémy Jacquier-Roux <jeremy.jacquier-roux@bonitasoft.com>

ENV BONITA_VERSION 6.5.1
ENV TOMCAT_VERSION 7.0.55
ENV BONITA_ARCHIVE_DIR BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}
ENV BONITA_ARCHIVE_FILE ${BONITA_ARCHIVE_DIR}.zip
ENV BASE_URL http://download.forge.ow2.org/bonita
ENV POSTGRES_JDBC_DRIVER_FILE postgresql-9.3-1102.jdbc41.jar
ENV POSTGRES_JDBC_DRIVER_URL https://jdbc.postgresql.org/download/${POSTGRES_JDBC_DRIVER_FILE}
ENV MYSQL_JDBC_DRIVER_ARCHIVE mysql-connector-java-5.1.26.zip
ENV MYSQL_JDBC_DRIVER_URL http://dev.mysql.com/get/Downloads/Connector-J/${MYSQL_JDBC_DRIVER_ARCHIVE}
ENV MYSQL_JDBC_DRIVER_FILE mysql-connector-java-5.1.26/mysql-connector-java-5.1.26-bin.jar

# perf
#ENV BENCH_MODE true
ENV BENCH_URL_ACTIVEMQ http://central.maven.org/maven2/org/apache/activemq/activemq-client/5.8.0/activemq-client-5.8.0.jar
ENV BENCH_URL_HAWTBUF http://central.maven.org/maven2/org/fusesource/hawtbuf/hawtbuf/1.9/hawtbuf-1.9.jar
ENV BENCH_URL_GERONIMO_JMS http://central.maven.org/maven2/org/apache/geronimo/specs/geronimo-jms_1.1_spec/1.1.1/geronimo-jms_1.1_spec-1.1.1.jar
ENV BENCH_URL_GERONIMO_J2EE http://central.maven.org/maven2/org/apache/geronimo/specs/geronimo-j2ee-management_1.1_spec/1.0.1/geronimo-j2ee-management_1.1_spec-1.0.1.jar

# avoid debconf messages
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update && \
 apt-get -y install software-properties-common

RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer && \
  apt-get update && \
  apt-get install -y postgresql-client \
  unzip \
  wget \
  && rm -rf /var/lib/apt/lists/*

COPY files /opt/files
COPY templates /opt/templates

# retrieve JDBC drivers
ADD ${POSTGRES_JDBC_DRIVER_URL} /opt/files/
ADD ${MYSQL_JDBC_DRIVER_URL} /opt/files/
RUN unzip /opt/files/${MYSQL_JDBC_DRIVER_ARCHIVE} -d /opt/files/

# add benchmark needed jars
ADD ${BENCH_URL_ACTIVEMQ} /opt/files/bench/
ADD ${BENCH_URL_HAWTBUF} /opt/files/bench/
ADD ${BENCH_URL_GERONIMO_JMS} /opt/files/bench/
ADD ${BENCH_URL_GERONIMO_J2EE} /opt/files/bench/


# add Bonita BPM archive to the container
ADD ${BASE_URL}/${BONITA_ARCHIVE_FILE} /opt/files/

# create Volume to store Bonita BPM files
VOLUME /opt/bonita

# create user to launch Bonita BPM as non-root
RUN groupadd -r bonita -g 1000 && \
  useradd -u 1000 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita

# expose Tomcat port
EXPOSE 8080

# command to run when container starts
CMD /opt/files/startup.sh
