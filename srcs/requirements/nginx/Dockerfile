FROM alpine:3.23

RUN apk add \
	nginx \
	openssl

RUN mkdir -p /etc/nginx/ssl \
    && chown -R nginx:nginx /etc/nginx/ssl

RUN openssl req -x509 -noenc -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/CN=maxrmax.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

CMD ["nginx", "-g", "daemon off;"]
