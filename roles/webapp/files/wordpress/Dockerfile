# penultimate alpine version (https://alpinelinux.org/cloud/)
FROM alpine:3.20

# install required packages
RUN apk add --no-cache bash php php-fpm php-phar php-mysqli php-json php-opcache php-mbstring php-curl php-pdo_mysql php-tokenizer curl mysql-client \
	&& mkdir -p /var/www/html \
	&& adduser -S -D -H -u 1000 -G www-data www-data \
	&& chown -R www-data:www-data /var/www \
	&& curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

# copy init script
COPY tools/wordpress_init.sh /wordpress_init.sh
RUN chmod +x /wordpress_init.sh
ENTRYPOINT ["/wordpress_init.sh"]
