FROM alpine:3.23

RUN apk add --no-cache \
	php84 \
	php84-fpm \
	php84-phar \
	php84-iconv \
	php84-mysqli \
	php84-openssl \
	php84-mbstring \
	mariadb-client \
	curl \
	&& rm -rf /var/cache/apk/*

# install wordpress-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

WORKDIR /var/www/html

COPY ./tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]
