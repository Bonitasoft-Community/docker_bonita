# SQL functions
function create_user_if_not_exists {
	if [ $# -ne 7 ]
	then
		echo 'Error'
		echo 'Usage : create_user_if_not_exists $db_vendor $db_host $db_port $db_admin_user $db_admin_pass $db_user $db_pass'
		exit 1
	fi
	db_vendor="$1"
	db_host="$2"
	db_port="$3"
	db_admin_user="$4"
	db_admin_pass="$5"
	db_user="$6"
	db_pass="$7"

	case "${db_vendor}" in
		mysql)
			# check if the user exists
			# if db_user already contains an @, strip that to the end of the string when verifying if user exists
			mysql -u $db_admin_user -p${db_admin_pass} -h $db_host --port $db_port -B -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${db_user%%@*}')" | tail -n 1 | grep -q 1
			# if the user is not present, create it
			if [ $? -eq 1 ]
			then
				# if db_user already contains an @, strip that to the end of the string when creating user
				mysql -u $db_admin_user -p${db_admin_pass} -h $db_host --port $db_port -e "CREATE USER '${db_user%%@*}'@'%' IDENTIFIED BY '${db_pass}';"
			fi
			;;
		postgres)
			export PGPASSWORD=$db_admin_pass
			# check if the user exists
			# if db_user already contains an @, strip that to the end of the string when verifying if user exists
			psql -U $db_admin_user -h $db_host -p $db_port -d postgres -t -A -c "SELECT 1 FROM pg_roles WHERE rolname='${db_user%%@*}'" | grep -q 1
			# if the user is not present, create it
			if [ $? -eq 1 ]
			then
				# if db_user already contains an @, strip that to the end of the string when creating user
				psql -U $db_admin_user -h $db_host -p $db_port -d postgres -c "CREATE USER ${db_user%%@*} WITH PASSWORD '${db_pass}'; GRANT ${db_user%%@*} TO $db_admin_user;"
			fi	
			;;
	esac
}

function create_database_if_not_exists {
	if [ $# -ne 9 ]
	then
		echo 'Error'
		echo 'Usage : create_database_if_not_exists $db_vendor $db_host $db_port $db_admin_user $db_admin_pass $db_name $db_user $db_pass $db_drop_existing'
		exit 1
	fi
	db_vendor="$1"
	db_host="$2"
	db_port="$3"
	db_admin_user="$4"
	db_admin_pass="$5"
	db_name="$6"
	db_user="$7"
	db_pass="$8"
	db_drop_existing="$9"

	case "${db_vendor}" in
		mysql)
			# drop database if said so
			if [ "$db_drop_existing" == "Y" ]
			then
				mysql -u $db_admin_user -p${db_admin_pass} -h $db_host --port $db_port -e "DROP DATABASE IF EXISTS ${db_name};"
			fi

			# if the db is not present, create it
			mysql -u $db_admin_user -p${db_admin_pass} -h $db_host --port $db_port -e "CREATE DATABASE IF NOT EXISTS ${db_name};"
			# if db_user already contains an @, strip that to the end of the string when granting privileges
			mysql -u $db_admin_user -p${db_admin_pass} -h $db_host --port $db_port -e "GRANT ALL PRIVILEGES ON ${db_name}.* to '${db_user%%@*}'@'%';"
			;;
		postgres)
			# drop database if said so
			if [ "$db_drop_existing" == "Y" ]
			then
				psql -U $db_admin_user -h $db_host -p $db_port -d postgres -c "DROP DATABASE IF EXISTS ${db_name};"
			fi

			# check if the db exists
			psql -U $db_admin_user -h $db_host -p $db_port -d postgres -l | grep ${db_name}
			# if the db is not present, create it
			if [ $? -eq 1 ]
			then
				# if db_user already contains an @, strip that to the end of the string when specifying database owner
				psql -U $db_admin_user -h $db_host -p $db_port -d postgres -c "CREATE DATABASE ${db_name} OWNER ${db_user%%@*};"
			fi
			;;
	esac
}

