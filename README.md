# Monorepo Laravel: Backend API & Frontend Livewire

Este monorepo contiene dos aplicaciones Laravel independientes, cada una en su propio contenedor Docker, pensadas para desarrollo local y despliegue automatizado.

## Estructura

- **backend/**: API Laravel (PHP 8.3, Nginx, MariaDB)
- **frontend/**: App Laravel Livewire (PHP 8.3, Nginx)
- **Makefile**: Automatiza setup, build, limpieza y otros comandos útiles
- **check_connectivity.sh**: Script para comprobar la conectividad entre frontend y backend

## Características principales

- Entorno reproducible y aislado con Docker Compose
- Submódulos independientes para backend y frontend (pueden ser repositorios separados)
- Automatización de setup: composer install, generación de claves, migraciones, etc.
- Red Docker compartida para comunicación entre servicios
- Scripts de ayuda para debug y conectividad

## Requisitos

- Docker y Docker Compose
- GNU Make
- Git (para clonar submódulos)

## Primer uso (clonado del monorepo)

1. Clona el monorepo y sus submódulos:
   ```sh
   git clone --recurse-submodules https://github.com/albrtogarcia/monorepo-laravel.git
   cd lm-monorepo
   ```

2. (Opcional) Actualiza los submódulos:
   ```sh
   git submodule update --init --recursive
   ```

3. Prepara el entorno completo:
   ```sh
   make setup
   ```
   Esto:
   - Copia .env.example a .env en cada app si no existe
   - Construye y levanta los contenedores
   - Instala dependencias composer
   - Genera claves de aplicación
   - Espera a que la base de datos esté lista (backend)
   - Ejecuta migraciones en backend

4. Accede a las apps:
   - **Backend API:** http://localhost:8010
   - **Frontend Livewire:** http://localhost:8020

## Comandos útiles

- `make help`      # Muestra ayuda y comandos disponibles
- `make setup`     # Prepara todo el entorno (build, up, composer, claves, migraciones)
- `make up`        # Levanta los contenedores
- `make build`     # Construye las imágenes Docker
- `make down`      # Detiene y elimina los contenedores y la red
- `make clean`     # Limpia todo el entorno

## Desarrollo con Vite y Hot Reload

Este monorepo está preparado para desarrollo moderno con Vite y hot reload tanto en backend como en frontend.

### Comandos útiles para desarrollo

- `make dev-backend`   # Lanza Vite en modo desarrollo en backend (puerto 5174)
- `make dev-frontend`  # Lanza Vite en modo desarrollo en frontend (puerto 5173)
- `make dev`           # Lanza Vite en modo desarrollo en backend y frontend en paralelo

Accede a las apps en:
- **Backend:** http://localhost:8010 (assets y hot reload por Vite en http://localhost:5174)
- **Frontend:** http://localhost:8020 (assets y hot reload por Vite en http://localhost:5173)

> Recuerda: Vite sirve los assets y el hot reload en los puertos 5173 (frontend) y 5174 (backend). Accede siempre a la app Laravel por los puertos 8010/8020.

---

## Debug y conectividad

- Usa `./check_connectivity.sh` para comprobar la red entre frontend y backend.
- Los logs de cada servicio pueden verse con `docker logs <nombre-contenedor>`.

## Notas

- El frontend no requiere base de datos por defecto, pero puedes añadirla si lo necesitas.
- Para instalar Livewire en frontend:
  ```sh
  docker exec lm-frontend-app composer require livewire/livewire
  ```
- Para añadir nuevos submódulos Laravel, repite la estructura y añade los pasos al Makefile.

---

## Flujo de trabajo recomendado para equipos con submódulos

### 1. Clonar el monorepo y los submódulos

```sh
git clone --recurse-submodules https://github.com/albrtogarcia/monorepo-laravel.git
cd lm-monorepo
```

Si ya tienes el monorepo y quieres actualizar los submódulos:
```sh
git submodule update --init --recursive
```

---

### 2. Trabajar en un submódulo (por ejemplo, backend)

```sh
cd backend/html
# Haz tus cambios, commits y push normalmente
git checkout -b feature/nueva-funcionalidad
# ...edita código...
git add .
git commit -m "feat: nueva funcionalidad"
git push origin feature/nueva-funcionalidad
```

---

### 3. Actualizar la referencia del submódulo en el monorepo

Después de hacer push en el submódulo, vuelve a la raíz del monorepo:

```sh
cd ../../  # desde backend/html a la raíz del monorepo
git add backend
git commit -m "update submodule backend to <SHA del último commit>"
git push
```

Haz lo mismo para frontend si trabajas ahí.

---

### 4. Sincronizar cambios de otros compañeros

Cuando otro compañero actualiza un submódulo y hace commit en el monorepo:

```sh
git pull --recurse-submodules
git submodule update --init --recursive
```

---

### 5. Recomendaciones

- Haz commits y push en los submódulos antes de actualizar la referencia en el monorepo.
- Usa mensajes claros en los commits del monorepo, por ejemplo:
  `update submodules: backend@abc123 frontend@def456`
- No edites el contenido de los submódulos desde la raíz del monorepo, hazlo siempre desde dentro del submódulo.
- Si hay conflictos de submódulos, resuélvelos como cualquier otro conflicto de Git.

---

### Mejoras

- [x] Añadir los repos como submodules del orquestador principal con `.gitmodules`. Con esto solo hay que clonar el orquestador y este clona los repos dependientes en subdirectorios:
- [ ] Pipelines de Bitbucket para CDCI.
- [ ] Soporte para entornos de producción y desarrollo. Pasar un parámetro (por ejemplo, make setup ENV=prod) para usar archivos .env.production, builds optimizados, etc.
- [ ] Comando Make para test. Agrega `make test` para ejecutar los tests de ambos proyectos desde la raíz, mostrando el resultado de cada uno.
- [ ] Logs centralizados. Agrega `make logs` para mostrar los logs de todos los servicios en tiempo real en una sola terminal.