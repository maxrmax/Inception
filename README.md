*This project has been created as part of the 42 curriculum by maxrmax*

# Inception

## Description
Inception is a system administration project that teaches Docker containerization through building a complete WordPress infrastructure. The project involves creating and orchestrating multiple Docker containers (NGINX, WordPress+PHP-FPM, MariaDB) with proper networking, volumes, and security configurations.

## Instructions

1. Clone the repository (inside Alpine VM)
2. Domain configuration:
	add `<login>.42.fr` to `127.0.0.1` in `/etc/hosts`
	if using redirection on the host due locked `/etc/hosts`:
	inside the guest, modify the `/srcs/.env` to contain `DOMAIN_NAME=127.0.0.1:8443`
3. Create and fill the `/srcs/.env` file:
```
DOMAIN_NAME=
SQL_DATABASE=wordress
SQL_USER=
SQL_PASSWORD=
SQL_ROOT_PASSWORD=
SQL_HOST=maridb
WP_TITLE=
WP_ADMIN_USER=
WP_ADMIN_PASSWORD=WP
WP_ADMIN_EMAIL=
WP_USER=
WP_USER_PASSWORD=
WP_USER_EMAIL=
```
3. Build the project `make all`
4. Access the service `<login>.42.fr`

#### Makefile Commands
```
make all		# Build images and start containers
make build		# Build images
make up			# Start containers
make down		# Stop containers
make clean		# Delete everything (needs sudo perms)
make logs		# Show Docker logs of all running containers
make ps			# Show all running containers
make restart	# Restart all containers
```

#### Software Stack
VM: Alpine
Docker container: Alpine images
1. NGINX
	- web server
	- TLS v1.2/v1.3 - self signed
	- shared WordPress volume
2. WordPress + php-fpm
	- Website
	- persistent storage volume
3. MariaDB
	- WordPress data storage
	- persistent storage volume

## Resources

Alpine *virtual x86_64 iso*
- https://alpinelinux.org/downloads/
- https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html

Docker
- https://docs.docker.com/reference/dockerfile/
- https://docs.docker.com/compose/compose-file/


NGINX
- https://nginx.org/en/docs/

TLS cert - openssl
- https://docs.openssl.org/master/man1/openssl-req/

WordPress
- https://wordpress.org/documentation/

php-fpm
- https://www.php.net/manual/en/install.fpm.php

MariaDB
- https://mariadb.com/docs/

### AI Usage
Research on guest OS. Debian vs Alpine, cli only options.
Research on Alpine. Pre-installed services, packagemanager usage.

After hours of unhelpful and unsuccessful debugging:
Dropped entirely, Accounts deleted, all references to AI removed.
The Solution was 5 characters long and with documentation ~12min. 

**AI? Wrong label.
It is not intelligent.
It is algorithmic.
I will now do it myself.
Real Intelligence bringing real results.**
