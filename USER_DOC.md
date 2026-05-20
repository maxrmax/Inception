# User documentation

## Provided Services
1. WordPress + php-fpm
	- Web Content Management System
	- Secure HTTPS connection
	- accessible via `<login>.42.fr`
2. MariaDB
	- Storage for WordPress content
3. NGINX
	- Web Server to route all traffic
	- Provides the TLS encryption

## Start and Stop the Project.
#### Building
In root of the repository for first time initialization:
`make all`
-> Build all Docker images
-> Start containers
-> intialize container content

#### Starting
**Disclaimer:** ***before the first build, set up `srcs/.env` yourself***


`make up`
WordPress can take up to a full minute to start up
403 Errors are expected during that time

#### Stopping
`make down`

#### Restarting
`make restart`
Stop, then start, all services.

## Accessing the Website and the Administration Panel
Assuming the services are running:
Visit `https://<login>.42.fr/wp-admin`
Insert credentials

## Manage Credentials
For ease of the project and access:
all credentials are stored at `/srcs/.env`
Admin, User, Database, WordPress.
***before the first build, set them yourself***

#### Changing Password after initial setup
Log into Admin panel
Change password of yourself or specific user.

## Check Running Services

check running containers
`make ps`

see all container logs
`make logs`

Indidivual container logs
`docker logs -f nginx`
`docker logs -f wordpress`
`docker logs -f mariadb`

