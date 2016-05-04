#!/bin/sh

# Set some JVM system properties required by Bonita BPM

# Bonita home folder (configuration files, temporary folder...) location
BONITA_HOME="-Dbonita.home=${CATALINA_HOME}/bonita"
PLATFORM_SETUP="-Dorg.bonitasoft.platform.setup.folder=${CATALINA_HOME}/platform-setup"
H2_DATABASE_DIR="-Dorg.bonitasoft.h2.database.dir=${CATALINA_HOME}/database"

# Define the RDMBS vendor use by Bonita Engine to store data
DB_OPTS="-Dsysprop.bonita.db.vendor={{DB_VENDOR}}"

# Define the RDMBS vendor use by Bonita Engine to store Business Data
# If you use different DB engines by tenants, please update directly bonita-tenant-community-custom.properties
BDM_DB_OPTS="-Dsysprop.bonita.bdm.db.vendor={{BIZ_DB_VENDOR}}"

# Bitronix (JTA service added to Tomcat and required by Bonita Engine for transaction management)
BTM_OPTS="-Dbtm.root=${CATALINA_HOME} -Dbitronix.tm.configuration=${CATALINA_HOME}/conf/bitronix-config.properties"

JAVA_OPTS="{{JAVA_OPTS}}"

# Optionnal JAAS configuration. Usually used when delgating authentication to LDAP / Active Directory server
#SECURITY_OPTS="-Djava.security.auth.login.config=${CATALINA_HOME}/conf/jaas-standard.cfg"

# Pass the JVM system properties to Tomcat JVM using CATALINA_OPTS variable
CATALINA_OPTS="${CATALINA_OPTS} ${BONITA_HOME} ${PLATFORM_SETUP} ${H2_DATABASE_DIR} ${DB_OPTS} ${BDM_DB_OPTS} ${BTM_OPTS} ${JAVA_OPTS} -Dfile.encoding=UTF-8 -Xshare:auto -Xms1024m -Xmx1024m -XX:MaxPermSize=256m -XX:+HeapDumpOnOutOfMemoryError"
export CATALINA_OPTS

# Only set CATALINA_PID if not already set (check for empty value) by startup script (usually done by /etc/init.d/tomcat7 but not by startup.sh nor catalina.sh)
if [ -z ${CATALINA_PID+x} ]; then
        CATALINA_PID=${CATALINA_BASE}/catalina.pid;
        export CATALINA_PID;
fi
