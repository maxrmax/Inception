FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/my.cnf.d/z99.cnf
COPY ./tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]
