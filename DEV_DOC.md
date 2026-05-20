# Developer Documentation
*VM installation and setup at the bottom of this document*
## Build from scratch
### Environment Setup
#### First Step: Cloning
`git clone <repo>`
`cd Inception`


#### Second Step: Environment Configuration
edit `srcs/.env`

if secrets are used:
create `secrets/`
`mkdir -p secrets`

`echo "pressword" > secrets/db_password.txt`
`echo "pressroot" > secrets/db_root_password.txt`
`echo "WPA" > secrets/wp_admin_password.txt`

be sure to use .gitignore and add `src/.env` and if used `secrets/`.
#### Third Step: Configure Domain Name
Modify `/etc/hosts` and add your Domain `[intra].42.fr` right after `127.0.0.1`
`sudo nano /etc/hosts`

```sh
127.0.0.1 [intra].42.fr .. .. .. localhost
```

#### Verify Setup

### Build and Start
#### Build
In the root of the repository:
`make build`
`docker images`
#### Start Services
`make up`
#### Inspect Services
`make ps`
`make logs`

### Container and Volume Management
#### Docker Compose
the `Makefile`, so `make` is accessing the file `srcs/docker-compose.yml` for every command
instead of using the make commands, you can run:

```sh
docker-compose -f srcs/docker-compose.yml ps
docker-compose -f srcs/docker-compose.yml logs [service]
docker-compose -f srcs/docker-compose.yml exec [service] [command]
docker-compose -f srcs/docker-compose.yml up -d --build [service]
docker-compose -f srcs/docker-compose.yml stop [service]
docker-compose -f srcs/docker-compose.yml restart [service]
docker-compose -f srcs/docker-compose.yml config
```

#### Debugging and Testing
You can also go directly into a container (shell access):
`docker exec -it <container> sh`

#### Volumes
```sh
docker volume ls
docker volume inspect <name>
docker volume prune
```
*docker volume prune only works if the volume is not associated to a container
that is usually the case after manually doing so*

#### Misc
view all volumes
`docker volume ls`
view all networks
`docker network ls`
view all build images
`docker images`
view all containers
`docker ps -a`

### Data Storage and Persistence
The Volumes are stored in `repo/data/`
```sh
Repository
|-- wordpress
\-- mariadb
```

Persistence is guaranteed through the storage of data outside of cointainers.
They are mounted/bound inside the container.
The communication between containers is guaranteed through the Docker Network.
I named this Network `Inception`, and its set up as a bridge.

Persistent data volumes are only removed on `make clean`

#### Verify Persistence
Change something in wordpress
`make restart`
Confirm

```sh
docker-compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p root_password pressroot -e "SHOW TABLES;"

docker-compose -f srcs/docker-compose.yml exec wordpress ls -la /var/www/html/
```

### File Structure
```sh
Inception
├── Makefile							# Duh
├── USER_DOC.md							# Duh
├── DEV_DOC.md							# Duh
├── .gitignore							# Duh
└── srcs/
	├── .env							# Environment variables
	├── docker-compose.yml				# Service definitions
	└── requirements/
		├── mariadb/
		│	├── Dockerfile				# MariaDB image
		│	├── conf/50-server.cnf		# Database config
		│	└── tools/init.sh			# Startup script
		├── wordpress/
		│	├── Dockerfile				# WordPress + PHP-FPM image
		│	├── conf/					# PHP config
		│	└── tools/setup.sh			# Installation script
		└── nginx/
			├── Dockerfile				# NGINX image
			├── conf/nginx.conf			# Web server config
			└── tools/					# Helper scripts
```

---

# Alpine VM
## Step 1 - Installing the VM guest
bind alpine iso
start vm

For small iso setup i recommend a single partition disk setup:
`fdisk /dev/sda` 
`o` -> build new DOS disklabel
`n` -> new partition
`p` -> primary
`1` -> partition number
`63` -> start sector
`[ENTER]` -> end sector
`a` -> bootable flag
`1` -> for partition 1
`p` -> print the partition table to confirm
`w` -> write the partition table
`mdev -s` -> scan hardware kernel for updated devices
`apk add e2fsprogs`
`mkfs.ext4 -O ^64bit /dev/sda1`
`mount -t ext4 /dev/sda1 /mnt`

run: `setup-alpine`
keyboard layout -> `us`
variant -> `us`
hostname -> `inception`
interface (internet) -> `eth0`
`dhcp`
network configuration ->  `n` (no manual configuration)
root password -> `password`
select timezone -> `Europe/` -> `Berlin`
proxy -> `none`
ntp client (time fetching, default busybox) -> `[ENTER]`
apk mirror -> press `[c]` to enable community mirror and then `[1]` to pick the main one
setup user? -> `no`
which ssh-server -> [openssh]
allow root login -> [yes]
enter root ssh key -> [none] (disable later)
ctrl+c here -> abort disk setup
create boot director -> `mkdir /mnt/boot`
setup the disk -> `setup-disk -m sys /mnt`
copys the files -> `dd bs=440 count=1 conv=notrunc if=/usr/share/syslinux/mbr.bin of=/dev/sda status=progress`
`dd if=/dev/urandom of=/dev/sda`
`poweroff`
unmount the installation iso and boot

---

## Step 2: Setting up the Environment

login of your choice (root/user)

if you didn't set [c] during install on the apk mirror:
`apk add nano`
`nano /etc/apk/repositories`
uncomment community mirror.
save

installing packages:
`apk update`
`apk upgrade`
`apk add [openrc] [nano] [docker] [docker-cli-compose] [git] [sudo] [make] [curl] [wget] [htop] [bash]` -> should be everything necessary
- OpenRC: init system and service manager (systemd alternative -> for docker autostart)
- nano: my editor of choice, done the entire project with it.
- docker: duh.
- git: so i can do everything in the vm
- curl: testing
- wget: testing
- htop: i like this one, so bonus
- sudo: duh
- bash: just in case

enable docker service at boot
`rc-update add docker default`
start docker service
`servie docker start`

create a docker group
`addgroup docker`
`addgroup [intra] docker`

don't forget to port forward in your vm:
`ssh host [PORT] guest [22]`
Be careful about blocked ports, you can set multiple ports to redirect to 22

---
## Step 3: Service Setup
### Nginx:
`srcs/requirements/nginx/Dockerfile`
```Dockerfile
# because :latest is forbidden, use specific version
FROM alpine:3.23

# what we run inside the container
# installing nginx and openssl - to keep it minimal we don't update/upgrade
RUN apk add \
        nginx \
        openssl

# creating the folder for ssl and owning it as nginx user
RUN mkdir -p /etc/nginx/ssl \
    && chown -R nginx:nginx /etc/nginx/ssl

# here we create our own certificate
RUN openssl req -x509 -noenc -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/CN=[intra].42.fr"

# here we copy the config file `./srcs/requirements/nginx/config/nginx.conf`
# into the docker container to the correct spot
COPY conf/nginx.conf /etc/nginx/nginx.conf

# which port the docker container will open/expose
EXPOSE 443

# how we run nginx -> `-g daemon off` means it runs in foreground.
# if we run only nginx, it would detatch and docker would think the container stopped running.
CMD ["nginx", "-g", "daemon off;"]
```

`srcs/requirements/nginx/conf/nginx.conf`
```nginx.conf
# event configuration: the maximum amount of connections per worker (1 worker -> 1024 connection)
events {
    worker_connections 1024;
}

# http protocol configuration
http {
	# map file extensions to Content-Types
    include /etc/nginx/mime.types;
	# fallback when no mapping exists
    default_type application/octet-stream;

    server {
		# listen on IPv4/IPv6 for https
        listen 443 ssl;
        listen [::]:443 ssl;

		# virtual host name
        server_name [intra].42.fr;

		# TLS certificate and private key
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        # mandatory: supported TLS version usage
		ssl_protocols TLSv1.2 TLSv1.3;
		# prefering server cipher order
        ssl_prefer_server_ciphers on;
		# cipher suite selecetion
		ssl_ciphers HIGH:!aNULL:!MD5;
        # hide nginx version in resposne
		server_tokens off;

		# all testing and access comes from a browser outside my vm
		# and /etc/hosts editing is as user not possible
		# my setup is made for that.
		# in a normal setup you would not use these two options below
		port_in_redirect off;
		absolute_redirect off;

        root /var/www/html;
        index index.html; # index.php;

		location / {
			try_files $uri $uri/ /index.php$is_args$args;
		}

		location ~ \.php$ {
			include fastcgi_params;
			fastcgi_param HTTPS on;
			fastcgi_pass wp:9000;
			fastcgi_index index.php;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		}
    }
}
```

---

### Wordpress

`srcs/requirements/wordpress/Dockerfile`
```Dockerfile
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
```

`srcs/requirements/wordpress/tools/setup.sh`
```sh
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
```

---

### MariaDB

`srcs/requirements/mariadb/Dockerfile`
```Dockerfile
FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/my.cnf.d/z99.cnf
COPY ./tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]
```

`srcs/requirements/mariadb/tools/init.sh`
```sh
#!/bin/sh
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    echo "Temp db start..."
    mariadbd --user=mysql --datadir=/var/lib/mysql &
    
    until mariadb-admin ping --silent; do
	echo "waiting for db availability..."
        sleep 1
    done

    echo "Running setup..."

    mariadb << EOF
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "Shutting down temp init server..."
    mariadb-admin -u root -p${SQL_ROOT_PASSWORD} shutdown
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --console
```

`srcs/requirements/mariadb/conf/my.cnf`
```cnf
[mysqld]
user         = mysql
datadir      = /var/lib/mysql
bind-address = 0.0.0.0
port         = 3306
skip-network = 0
```

---

## Docker Compose
`srcs/docker-compose.yml`
```yml
services:
  mariadb:
    build:
      context: ./requirements/mariadb
    image: mariadb:latest
    container_name: mariadb
    env_file: .env
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - inception
    restart: always

  wordpress:
    build:
      context: ./requirements/wordpress
    image: wp:latest
    container_name: wp
    depends_on:
      - mariadb
    env_file: .env
    volumes:
      - wp_data:/var/www/html
    networks:
      - inception
    restart: always

  nginx:
    build:
      context: ./requirements/nginx
    image: nginx:latest
    container_name: nginx
    depends_on:
      - wordpress
    ports:
      - "443:443"
    volumes:
      - wp_data:/var/www/html
    networks:
      - inception
    restart: always

networks:
  inception:
    driver: bridge
    name: inception

volumes:
  db_data:
    name: mariadb
    driver: local
    driver_opts:
      type: none
      o: bind
      device:./data/mariadb
  wp_data:
    name: wp
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/wordpress
```

---

## Makefile

`Makefile`
```Makefile
FILE = ./srcs/docker-compose.yml

all: build .WAIT up

build:
	mkdir -p ./data/mariadb/ ./data/wordpress/
	docker compose -f $(FILE) build
	docker builder prune -af

up:
	docker compose -f $(FILE) up -d

down:
	docker compose -f $(FILE) down 

clean: down
	docker system prune -af --volumes
	docker volume rm wp mariadb || true
	sudo rm -rf ./data/mariadb ./data/wordpress
	sudo mkdir -p ./data/mariadb ./data/wordpress

logs:
	docker compose -f $(FILE) logs

ps:
	docker compose -f $(FILE) ps

restart: down .WAIT up

.PHONY: all build up down clean logs ps restart eval

```

---

# Misc. and Good to knows

On your host machine, if you are using modern or customized terminals:
add this to the `~/.ssh/config`
```
Host *
  SetEnv TERM=xterm-256color
```
why? compability for using terminal editor when connecting per ssh
forces your local terminal type (TERM) to be sent to the remote host
so full‑screen and color terminal apps (nano, vim, tmux) render and behave correctly

---

if you want to add an ssh key and can't copy paste into your VM,
enable root@vm login and scp your key into the vm.
`nano /etc/ssh/sshd_config`
we want the following settings:
```
PermitRootLogin yes
PermitEmptyPasswords yes
```
save and restart the sshd service
`service sshd restart`

now on your host you can
`scp ~/.ssh/key root@localhost:2222:/home/[intra]/.ssh/`
remember to set port forwarding in the vm for ssh `host [PORT] guest 22`
and revert the `sshd_config` settings for security

---
If you add an user after the install you have to do the permissions properly
`adduser [intra]` -> sudo WILL need a password
`addgroup [intra] wheel` for sudo
`chmod 700 /home/[intra]` for proper permissions
`export EDITOR=nano` (if you want to use nano instead of vi)
`export VISUAL=nano`
`visudo` and uncomment %wheel ALL=(ALL:ALL) ALL
`ctrl+x` or `:wq` to save and close
now [intra] can use sudo

ssh folder needs 700 and to be owned by the correct user
confirm permissions or just set them:
`chmod 700 .ssh`
`chown -R [intra]:[intra] .ssh`
`chmod 600 .ssh/authorized_keys`