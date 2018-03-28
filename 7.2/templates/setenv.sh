#!/bin/sh

# Set some JVM system properties required by Bonita BPM

# Bonita home folder (configuration files, temporary folder...) location
BONITA_HOME="-Dbonita.home=${CATALINA_HOME}/bonita"

# Define the RDMBS vendor use by Bonita Engine to store data
DB_OPTS="-Dsysprop.bonita.db.vendor={{DB_VENDOR}}"

# Bitronix (JTA service added to Tomcat and required by Bonita Engine for transaction management)
BTM_OPTS="-Dbtm.root=${CATALINA_HOME} -Dbitronix.tm.configuration=${CATALINA_HOME}/conf/bitronix-config.properties"

JAVA_OPTS="{{JAVA_OPTS}}"

# Optionnal JAAS configuration. Usually used when delgating authentication to LDAP / Active Directory server
#SECURITY_OPTS="-Djava.security.auth.login.config=${CATALINA_HOME}/conf/jaas-standard.cfg"

# Pass the JVM system properties to Tomcat JVM using CATALINA_OPTS variable
CATALINA_OPTS="${CATALINA_OPTS} ${BONITA_HOME} ${DB_OPTS} ${BTM_OPTS} ${JAVA_OPTS} -Dfile.encoding=UTF-8 -Xshare:auto -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${CATALINA_HOME}/logs -Djava.security.egd=file:/dev/./urandom"
export CATALINA_OPTS

# Only set CATALINA_PID if not already set (check for empty value) by startup script (usually done by /etc/init.d/tomcat7 but not by startup.sh nor catalina.sh)
if [ -z ${CATALINA_PID+x} ]; then
        CATALINA_PID=${CATALINA_BASE}/catalina.pid;
        export CATALINA_PID;
fi
