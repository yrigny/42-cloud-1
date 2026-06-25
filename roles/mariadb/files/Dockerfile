# penultimate alpine version (https://alpinelinux.org/cloud/)
FROM alpine:3.20

# install MariaDB
RUN apk add --no-cache mariadb mariadb-client mariadb-server-utils \
	&& mkdir -p /run/mysqld && chown -R mysql:mysql /var/lib/mysql /run/mysqld

# copy entrypoint script
RUN rm /etc/my.cnf
COPY conf/server.cnf /etc/my.cnf
COPY tools/mariadb_init.sh /mariadb_init.sh
RUN chmod +x /mariadb_init.sh

ENTRYPOINT ["/mariadb_init.sh"]