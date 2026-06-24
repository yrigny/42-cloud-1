#!/bin/bash

# get secrets
export MYSQL_PASSWORD="${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
export WP_ADM_PWD="${WP_ADM_PWD:?WP_ADM_PWD is required}"
export WP_PWD="${WP_PWD:?WP_PWD is required}"

# wait for the database
echo "Waiting for database connection..."
until mysqladmin ping -h "mariadb" --silent; do
	sleep 2
done
echo "Database is ready!"

cd /var/www/html

# keep wp-config aligned with the current environment on every boot
# this avoids stale database constants on a persisted volume
if [ -f wp-config.php ]; then
	wp config set DB_NAME "${MYSQL_DATABASE}" --allow-root --path=/var/www/html
	wp config set DB_USER "${MYSQL_USER}" --allow-root --path=/var/www/html
	wp config set DB_PASSWORD "${MYSQL_PASSWORD}" --allow-root --path=/var/www/html
	wp config set DB_HOST "mariadb:3306" --allow-root --path=/var/www/html
fi

# download WordPress files and install WordPress
if [ ! -f wp-config.php ]; then
	echo "Downloading WordPress..."
	rm -rf *
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/latest.tar.gz"
	tar xzf wordpress.tar.gz
	mv wordpress/* .
	rm -rf wordpress.tar.gz wordpress
	sleep 2
	wp config create --force --allow-root \
		--dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" \
		--dbpass="${MYSQL_PASSWORD}" --dbhost="mariadb:3306"
	echo "Installing WordPress core..."
	wp core install --allow-root --path=/var/www/html --url="${DOMAIN_NAME}" --title="${WP_TITLE}" \
		--admin_user="${WP_ADM_USR}" --admin_password="${WP_ADM_PWD}" \
		--admin_email="${WP_ADM_EML}"
	echo "Creating default user..."
	wp user create --allow-root --path=/var/www/html "${WP_USR}" "${WP_EML}" --role=author --user_pass="${WP_PWD}"
fi

# keep credentials in sync with the rendered env file on every boot
# the site may already exist when this container restarts
if wp --path=/var/www/html core is-installed --allow-root; then
	echo "Syncing admin credentials..."
	wp --path=/var/www/html eval --allow-root 'if ($user = get_user_by("login", getenv("WP_ADM_USR"))) { wp_set_password(getenv("WP_ADM_PWD"), $user->ID); echo "Admin password updated\n"; } else { echo "Admin user not found\n"; }'
	wp --path=/var/www/html user update "${WP_ADM_USR}" --user_email="${WP_ADM_EML}" --allow-root
	wp --path=/var/www/html user list --field=user_login --allow-root | grep -qx "${WP_USR}" || \
		wp --path=/var/www/html user create "${WP_USR}" "${WP_EML}" --role=author --user_pass="${WP_PWD}" --allow-root
fi

# keep php-fpm reachable from nginx on every boot
chown -R www-data:www-data /var/www/html
sed -i 's|user = nobody|user = www-data|' /etc/php83/php-fpm.d/www.conf
sed -i 's|group = nobody|group = www-data|' /etc/php83/php-fpm.d/www.conf
sed -i 's|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|' /etc/php83/php-fpm.d/www.conf

# start PHP-FPM
exec php-fpm83 -F
