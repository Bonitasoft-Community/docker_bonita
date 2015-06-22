#!/bin/bash
set -x
# Path to deploy the Tomcat Bundle
BONITA_PATH=${BONITA_PATH:-/opt/bonita}
# Templates directory
BONITA_TPL=${BONITA_TPL:-/opt/templates}
# Files directory
BONITA_FILES=${BONITA_FILES:-/opt/files}
# Flag to allow or not the SQL queries to automatically check and create the databases
ENSURE_DB_CHECK_AND_CREATION=${ENSURE_DB_CHECK_AND_CREATION:-true}
# Java OPTS
JAVA_OPTS=${JAVA_OPTS:--Xms1024m -Xmx1024m -XX:MaxPermSize=256m}
# Flag to enable or not dynamic authorization checking on Bonita REST API
REST_API_DYN_AUTH_CHECKS=${REST_API_DYN_AUTH_CHECKS:-true}
# Flag to enable or not Bonita HTTP API
HTTP_API=${HTTP_API:-false}

# retrieve the db parameters from the container linked
if [ -n "$POSTGRES_PORT_5432_TCP_PORT" ]
then
	DB_VENDOR='postgres'
	DB_HOST=$POSTGRES_PORT_5432_TCP_ADDR
	DB_PORT=$POSTGRES_PORT_5432_TCP_PORT
	JDBC_DRIVER=$POSTGRES_JDBC_DRIVER_FILE
	BIZ_DB_VENDOR='postgres'
elif [ -n "$MYSQL_PORT_3306_TCP_PORT" ]
then
	DB_VENDOR='mysql'
	DB_HOST=$MYSQL_PORT_3306_TCP_ADDR
	DB_PORT=$MYSQL_PORT_3306_TCP_PORT
	JDBC_DRIVER=$MYSQL_JDBC_DRIVER_FILE
	BIZ_DB_VENDOR='mysql'
else
	DB_VENDOR='h2'
	BIZ_DB_VENDOR='h2'
fi

# if not enforced, set the default values to configure the databases
DB_NAME=${DB_NAME:-bonitadb}
DB_USER=${DB_USER:-bonitauser}
DB_PASS=${DB_PASS:-bonitapass}
BIZ_DB_NAME=${BIZ_DB_NAME:-businessdb}
BIZ_DB_USER=${BIZ_DB_USER:-businessuser}
BIZ_DB_PASS=${BIZ_DB_PASS:-businesspass}

# if not enforced, set the default credentials
PLATFORM_LOGIN=${PLATFORM_LOGIN:-platformAdmin}
PLATFORM_PASSWORD=${PLATFORM_PASSWORD:-platform}
TENANT_LOGIN=${TENANT_LOGIN:-install}
TENANT_PASSWORD=${TENANT_PASSWORD:-install}

if [ ! -d ${BONITA_PATH}/${BONITA_ARCHIVE_DIR} ]
then
        unzip -q ${BONITA_FILES}/${BONITA_ARCHIVE_FILE} -d ${BONITA_PATH}
fi

if [ "${ENSURE_DB_CHECK_AND_CREATION}" = 'true' ]
then
	# load SQL functions
	. ${BONITA_FILES}/functions.sh
	case "${DB_VENDOR}" in
		mysql)
			db_admin_user='root'
			db_admin_pass=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}
			;;
		postgres)
			db_admin_user='postgres'
			db_admin_pass=$POSTGRES_ENV_POSTGRES_PASSWORD
			;;
	esac
	if [ "${DB_VENDOR}" != 'h2' ]
	then
		# ensure to create bonita db and user
		create_user_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $db_admin_user $db_admin_pass $DB_USER $DB_PASS
		create_database_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $db_admin_user $db_admin_pass $DB_NAME $DB_USER
		# ensure to create business db and user if needed
		create_user_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $db_admin_user $db_admin_pass $BIZ_DB_USER $BIZ_DB_PASS
		create_database_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $db_admin_user $db_admin_pass $BIZ_DB_NAME $BIZ_DB_USER
	fi
fi

# apply conf
# copy templates
cp ${BONITA_TPL}/bonita-platform-community-custom.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/engine-server/conf/bonita-platform-community-custom.properties
cp ${BONITA_TPL}/bonita-tenant-community-custom.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/engine-server/conf/tenants/template/bonita-tenant-community-custom.properties
cp ${BONITA_TPL}/platform-tenant-config.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/client/platform/conf/platform-tenant-config.properties
cp ${BONITA_TPL}/setenv.sh ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bin/setenv.sh

# if required, uncomment dynamic checks on REST API
if [ "$REST_API_DYN_AUTH_CHECKS" = 'true' ]
then
    sed -i -e 's/^#GET|/GET|/' -e 's/^#POST|/POST|/' -e 's/^#PUT|/PUT|/' -e 's/^#DELETE|/DELETE|/' ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/client/platform/tenant-template/conf/dynamic-permissions-checks.properties
fi
# if required, deactivate HTTP API by updating bonita.war with proper web.xml
if [ "$HTTP_API" = 'false' ]
then
    cd ${BONITA_FILES}/
    zip ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/webapps/bonita.war WEB-INF/web.xml
fi

# replace variables
sed -e 's/{{TENANT_LOGIN}}/'"${TENANT_LOGIN}"'/' \
    -e 's/{{TENANT_PASSWORD}}/'"${TENANT_PASSWORD}"'/' \
    -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/engine-server/conf/tenants/template/bonita-tenant-community-custom.properties \
       ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/client/platform/conf/platform-tenant-config.properties
sed -e 's/{{PLATFORM_LOGIN}}/'"${PLATFORM_LOGIN}"'/' \
    -e 's/{{PLATFORM_PASSWORD}}/'"${PLATFORM_PASSWORD}"'/' \
    -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/engine-server/conf/platform/bonita-platform-community-custom.properties
sed 's/{{DB_VENDOR}}/'"${DB_VENDOR}"'/' -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bin/setenv.sh
sed 's/{{JAVA_OPTS}}/'"${JAVA_OPTS}"'/' -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bin/setenv.sh
sed -e 's/{{BIZ_DB_VENDOR}}/'"${BIZ_DB_VENDOR}"'/' \
    -i ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/bonita/engine-server/conf/tenants/template/bonita-tenant-community-custom.properties
case "${DB_VENDOR}" in
	mysql|postgres)
		cp ${BONITA_TPL}/${DB_VENDOR}/bitronix-resources.properties ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/conf/bitronix-resources.properties
		cp ${BONITA_TPL}/${DB_VENDOR}/bonita.xml ${BONITA_PATH}/${BONITA_ARCHIVE_DIR}/conf/Catalina/localhost/bonita.xml
		sed -e 's/{{DB_USER}}/'"${DB_USER}"'/' \
		    -e 's/{{DB_PASS}}/'"${DB_PASS}"'/' \
		    -e 's/{{DB_NAME}}/'"${DB_NAME}"'/' \
		    -e 's/{{DB_HOST}}/'"${DB_HOST}"'/' \
		    -e 's/{{DB_PORT}}/'"${DB_PORT}"'/' \
		    -e 's/{{BIZ_DB_USER}}/'"${BIZ_DB_USER}"'/' \
		    -e 's/{{BIZ_DB_PASS}}/'"${BIZ_DB_PASS}"'/' \
		    -e 's/{{BIZ_DB_NAME}}/'"${BIZ_DB_NAME}"'/' \
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
