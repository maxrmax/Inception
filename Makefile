FILE = srcs/docker-compose.yml

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
