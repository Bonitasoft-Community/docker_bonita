#!/bin/bash
# Path to deploy the tomcat Bundle
BONITA_PATH=${BONITA_PATH:-/opt/bonita}
# Templates directory
BONITA_TPL=${BONITA_TPL:-/opt/templates}
# Files directory
BONITA_FILES=${BONITA_FILES:-/opt/files}
# Flag to allow or not SQL queries to automatically check and create the database
ENSURE_DB_CHECK_AND_CREATION=${ENSURE_DB_CHECK_AND_CREATION:-true}
#Java OPTS
export JAVA_OPTS=${JAVA_OPTS:--Xms1024m -Xmx1024m -XX:MaxPermSize=256m}

# retrieve db parameters from container linked
if [ -n "$POSTGRES_PORT_5432_TCP_PORT" ]
then
	DB_VENDOR='postgres'
        DB_HOST=$POSTGRES_PORT_5432_TCP_ADDR
        DB_PORT=$POSTGRES_PORT_5432_TCP_PORT
	JDBC_DRIVER=$POSTGRES_JDBC_DRIVER_FILE
elif [ -n "$MYSQL_PORT_3306_TCP_PORT" ]
then
	DB_VENDOR='mysql'
        DB_HOST=$MYSQL_PORT_3306_TCP_ADDR
        DB_PORT=$MYSQL_PORT_3306_TCP_PORT
        JDBC_DRIVER=$MYSQL_JDBC_DRIVER_FILE
else
	DB_VENDOR='h2'
fi

# Flag to allow benchmark 
BENCH_MODE=${BENCH_MODE:false}

# if not enforced, set default values to configure the db
DB_NAME=${DB_NAME:-bonitadb}
DB_USER=${DB_USER:-bonitauser}
DB_PASS=${DB_PASS:-bonitapass}

# if not enforced, set default credentials
PLATFORM_LOGIN=${PLATFORM_LOGIN:-platformAdmin}
PLATFORM_PASSWORD=${PLATFORM_PASSWORD:-platform}
TENANT_LOGIN=${TENANT_LOGIN:-install}
TENANT_PASSWORD=${TENANT_PASSWORD:-install}

if [ ! -d ${BONITA_PATH}/${BONITA_ARCHIVE_DIR} ]
then
        unzip ${BONITA_FILES}/${BONITA_ARCHIVE_FILE} -d ${BONITA_PATH}
fi

if [ "${BENCH_MODE}" = 'true' ]
then
	cp ${BONITA_FILES}/bench/* ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/lib/
fi

if [ "${ENSURE_DB_CHECK_AND_CREATION}" = 'true' ]
then
# create bonita db and user if needed
case "${DB_VENDOR}" in
	mysql)
		# check if user exists
		mysql -u root -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h $DB_HOST --port $DB_PORT -B -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${DB_USER}')" | tail -n 1 | grep -q 1
	        # if user is not present, create it
        	if [ $? -eq 1 ]
	        then
        	        mysql -u root -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h $DB_HOST --port $DB_PORT -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
	        fi
        	# if db is not present, create it
		mysql -u root -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h $DB_HOST --port $DB_PORT -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
        	mysql -u root -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h $DB_HOST --port $DB_PORT -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';"
		;;
	postgres)
		export PGPASSWORD=$POSTGRES_ENV_POSTGRES_PASSWORD
		# check if user exists
		psql -U postgres -h $DB_HOST -p $DB_PORT -d postgres -t -A -c "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1
		# if user is not present, create it
		if [ $? -eq 1 ]
		then
			psql -U postgres -h $DB_HOST -p $DB_PORT -d postgres -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
		fi
		# check if db exists
		psql -U postgres -h $DB_HOST -p $DB_PORT -d postgres -l | grep ${DB_NAME}
		# if db is not present, create it
		if [ $? -eq 1 ]
		then
			psql -U postgres -h $DB_HOST -p $DB_PORT -d postgres -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
		fi
		;;
esac
fi

# apply conf
# copy templates
cp ${BONITA_TPL}/bonita-server.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/server/platform/tenant-template/conf/bonita-server.properties
cp ${BONITA_TPL}/platform-tenant-config.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/client/platform/conf/platform-tenant-config.properties
cp ${BONITA_TPL}/bonita-platform.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/server/platform/conf/bonita-platform.properties
cp ${BONITA_TPL}/setenv.sh ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bin/setenv.sh
# replace variables
sed -e 's/{{TENANT_LOGIN}}/'"${TENANT_LOGIN}"'/' \
    -e 's/{{TENANT_PASSWORD}}/'"${TENANT_PASSWORD}"'/' \
    -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/server/platform/tenant-template/conf/bonita-server.properties \
       ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/client/platform/conf/platform-tenant-config.properties
sed -e 's/{{PLATFORM_LOGIN}}/'"${PLATFORM_LOGIN}"'/' \
    -e 's/{{PLATFORM_PASSWORD}}/'"${PLATFORM_PASSWORD}"'/' \
    -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/server/platform/conf/bonita-platform.properties
sed 's/{{DB_VENDOR}}/'"${DB_VENDOR}"'/' -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bin/setenv.sh
sed 's/{{JAVA_OPTS}}/'"${JAVA_OPTS}"'/' -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bin/setenv.sh

case "${DB_VENDOR}" in
	mysql|postgres)
        	cp ${BONITA_TPL}/${DB_VENDOR}/bitronix-resources.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/conf/bitronix-resources.properties
	        cp ${BONITA_TPL}/${DB_VENDOR}/bonita.xml ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/conf/Catalina/localhost/bonita.xml
		sed -e 's/{{DB_USER}}/'"${DB_USER}"'/' \
		    -e 's/{{DB_PASS}}/'"${DB_PASS}"'/' \
		    -e 's/{{DB_HOST}}/'"${DB_HOST}"'/' \
		    -e 's/{{DB_PORT}}/'"${DB_PORT}"'/' \
		    -e 's/{{DB_NAME}}/'"${DB_NAME}"'/' \
		    -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/conf/bitronix-resources.properties \
		       ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/conf/Catalina/localhost/bonita.xml

        	# if not present, move JDBC driver into the Bundle
	        file=$(basename $JDBC_DRIVER)
        	if [ ! -e ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/lib/bonita/$file ]
	        then
        	        mv ${BONITA_FILES}/${JDBC_DRIVER} ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/lib/bonita/
	        fi
		;;
esac
