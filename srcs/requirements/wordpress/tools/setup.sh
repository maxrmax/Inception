#!/bin/sh

WP="php -d memory_limit=512M /usr/local/bin/wp --allow-root"

sed -i 's/listen = .*/listen = 0.0.0.0:9000/' /etc/php84/php-fpm.d/www.conf

while ! nc -w 1 "$SQL_HOST" 3306 > /dev/null 2>&1; do
	echo -n '.'
	sleep 1
done
echo -e "\nMariaDB is up."

if [ ! -f /var/www/html/wp-config.php ]; then
	echo "Installing WordPress.."

	$WP core download
	
	$WP config create --allow-root \
		--dbname=$SQL_DATABASE \
		--dbuser=$SQL_USER \
		--dbpass=$SQL_PASSWORD \
		--dbhost=$SQL_HOST

	$WP core install --allow-root \
		--url=$DOMAIN_NAME \
		--title="$WP_TITLE" \
		--admin_user=$WP_ADMIN_USER \
		--admin_password=$WP_ADMIN_PASSWORD \
		--admin_email=$WP_ADMIN_EMAIL

	$WP user create $WP_USER $WP_USER_EMAIL \
		--role=author \
		--user_pass=$WP_USER_PASSWORD \
		--allow-root

	chown -R www-data:www-data /var/www/html
	echo "WordPress installed."
fi

mkdir -p /run/php

echo "Running PHP-FPM.."

sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/g' /etc/php84/php-fpm.d/www.conf
sed -i 's/;error_log = log\/php84\/error.log/error_log = \/proc\/self\/fd\/2/g' /etc/php84/php-fpm.conf

exec /usr/sbin/php-fpm84 -F
