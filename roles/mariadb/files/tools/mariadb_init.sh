#!/bin/sh

# get secrets
export MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
export MYSQL_PASSWORD="${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

# if workdir empty, init MariaDB
if [ -z "$(ls -A /var/lib/mysql)" ]; then
	echo "Initializing database..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql

	# start in daemon
	# run a temporary server to seed the initial schema and users
	mysqld --user=mysql --skip-networking &
	pid="$!"

	# wait to be fully started
	i=30
	while [ "$i" -ge 0 ]; do
		if mysqladmin ping --silent; then
			break
		fi
		echo "Waiting for MariaDB to start... ($i)"
		sleep 1
		i=$((i - 1))
	done

	# delete anonymous users, create root user and normal user, create db
	mysql -uroot <<-EOSQL
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
		FLUSH PRIVILEGES;
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
EOSQL

	# stop MariaDB
	kill "$pid"
	wait "$pid"
fi

# keep credentials in sync with the rendered env file on every boot
# this keeps a pruned volume or password change aligned with Vault values
mysqld --user=mysql --skip-networking &
pid="$!"

# wait to be fully started
i=30
while [ "$i" -ge 0 ]; do
	if mysqladmin ping --silent; then
		break
	fi
	echo "Waiting for MariaDB to start for credential sync... ($i)"
	sleep 1
	i=$((i - 1))
done

mysql -uroot <<-EOSQL
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
	CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
	ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
	GRANT ALL ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
	CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
	ALTER USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
	GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
	FLUSH PRIVILEGES;
EOSQL

kill "$pid"
wait "$pid"

exec mysqld --user=mysql