# Makefile para levantar, bajar y limpiar el entorno completo de un monorepo Laravel con Docker
.PHONY: up down build setup clean help

# Detecta el sed compatible con el sistema operativo
SED_INPLACE = $(shell if sed --version 2>/dev/null | grep -q GNU; then echo "-i"; else echo "-i ''"; fi)

# Levanta la red y los contenedores de backend y frontend
up:
	# Crea la red si no existe
	docker network inspect lm-monorepo-net >/dev/null 2>&1 || docker network create --subnet=172.31.0.0/16 lm-monorepo-net
	# Levanta los servicios de backend y frontend
	docker compose -f backend/docker-compose.yml up -d
	docker compose -f frontend/docker-compose.yml up -d

# Detiene y elimina los contenedores y la red
down:
	# Detiene y elimina los servicios de backend y frontend
	docker compose -f backend/docker-compose.yml down -v --remove-orphans
	docker compose -f frontend/docker-compose.yml down -v --remove-orphans
	# Elimina la red si existe
	docker network rm lm-monorepo-net || true

# Construye las imágenes Docker de backend y frontend
build:
	# Construye las imágenes de backend
	docker compose -f backend/docker-compose.yml build
	# Construye las imágenes de frontend
	docker compose -f frontend/docker-compose.yml build

# Prepara el entorno completo: copia .env, ajusta DB, instala dependencias, genera claves, espera DB, migra
setup: build up
	# Copia .env.example a .env si no existe en backend y frontend
	@for app in backend frontend; do \
		if [ -f $$app/html/.env ]; then rm $$app/html/.env; fi; \
		if [ -f $$app/html/.env.example ]; then \
			cp $$app/html/.env.example $$app/html/.env; \
			echo "Copiado .env.example a .env en $$app/html"; \
		fi; \
	done
	# Refuerza la configuración de MariaDB en backend/html/.env (añade o reemplaza)
	@echo "Ajustando configuración de base de datos en backend..."
	grep -q '^DB_CONNECTION=' backend/html/.env && \
		sed $(SED_INPLACE) 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' backend/html/.env || \
		echo 'DB_CONNECTION=mysql' >> backend/html/.env
	grep -q '^DB_HOST=' backend/html/.env && \
		sed $(SED_INPLACE) 's/^DB_HOST=.*/DB_HOST=lm-backend-db/' backend/html/.env || \
		echo 'DB_HOST=lm-backend-db' >> backend/html/.env
	grep -q '^DB_PORT=' backend/html/.env && \
		sed $(SED_INPLACE) 's/^DB_PORT=.*/DB_PORT=3306/' backend/html/.env || \
		echo 'DB_PORT=3306' >> backend/html/.env
	grep -q '^DB_DATABASE=' backend/html/.env && \
		sed $(SED_INPLACE) 's/^DB_DATABASE=.*/DB_DATABASE=laravel/' backend/html/.env || \
		echo 'DB_DATABASE=laravel' >> backend/html/.env
	grep -q '^DB_USERNAME=' backend/html/.env && \
		sed $(SED_INPLACE) 's/^DB_USERNAME=.*/DB_USERNAME=laravel/' backend/html/.env || \
		echo 'DB_USERNAME=laravel' >> backend/html/.env
	grep -q '^DB_PASSWORD=' backend/html/.env && \
		sed $(SED_INPLACE) 's/^DB_PASSWORD=.*/DB_PASSWORD=secret/' backend/html/.env || \
		echo 'DB_PASSWORD=secret' >> backend/html/.env
	# Instala dependencias composer y genera clave en backend
	@echo "Instalando dependencias composer en backend..."
	docker exec lm-backend-api composer install --working-dir=/var/www/html
	@echo "Generando clave de aplicación en backend..."
	docker exec lm-backend-api php artisan key:generate
	# Espera a que la base de datos esté lista antes de migrar
	@echo "Esperando a que la base de datos del backend esté lista..."
	@until docker exec lm-backend-api php /var/www/html/checkdb.php | grep OK; do \
		echo "Aún no hay conexión, reintentando..."; \
		sleep 2; \
	done
	# Ejecuta migraciones en backend
	@echo "Ejecutando migraciones en backend..."
	docker exec lm-backend-api php artisan migrate --force
	# Instala dependencias composer y genera clave en frontend
	@echo "Instalando dependencias composer en frontend..."
	docker exec lm-frontend-app composer install --working-dir=/var/www/html
	@echo "Generando clave de aplicación en frontend..."
	docker exec lm-frontend-app php artisan key:generate
	# Si el frontend usa sqlite, crea el archivo database.sqlite vacío si no existe
	@if grep -q '^DB_CONNECTION=sqlite' frontend/html/.env; then \
		mkdir -p frontend/html/database; \
		touch frontend/html/database/database.sqlite; \
		echo "Archivo database.sqlite creado en frontend/html/database/"; \
	fi

# Limpia todo el entorno (down + elimina red)
clean: down

# Muestra ayuda y comandos disponibles
help:
	@echo "Comandos útiles para el monorepo Laravel:";
	@echo "  make help      # Muestra esta ayuda";
	@echo "  make setup     # Prepara el entorno completo: build, up, composer, claves, migraciones";
	@echo "  make up        # Levanta todos los contenedores (requiere build previo si es la primera vez)";
	@echo "  make build     # Construye las imágenes Docker de backend y frontend";
	@echo "  make down      # Detiene y elimina todos los contenedores y la red";
	@echo "  make clean     # Limpia todo el entorno (down + elimina red)";
