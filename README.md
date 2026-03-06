# Generador de BPMN con IA

Aplicación web full-stack para analizar documentos PDF y generar diagramas BPMN (Business Process Model and Notation) asistidos por IA. Incluye sistema de autenticación con roles, gestión de usuarios y panel de administración.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    Navegador                        │
│            http://localhost (puerto 80)             │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              nginx (contenedor frontend)            │
│  ┌──────────────────────────────────────────────┐   │
│  │  Archivos estáticos Angular (SPA)            │   │
│  │  /api/*     → proxy → backend:3000           │   │
│  │  /uploads/* → proxy → backend:3000           │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│          backend Node.js/Express (puerto 3000)      │
│  - Autenticación (bcrypt)                           │
│  - CRUD de usuarios                                 │
│  - Imágenes de perfil                               │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│           PostgreSQL 16 (contenedor db)             │
│  - Tabla users                                      │
│  - Datos semilla (Admin + Usuario de prueba)        │
└─────────────────────────────────────────────────────┘
```

### Servicios Docker

| Servicio   | Imagen                | Puerto expuesto | Descripción                          |
|------------|----------------------|-----------------|--------------------------------------|
| `db`       | `postgres:16-alpine` | interno         | Base de datos PostgreSQL             |
| `backend`  | Node.js 22 Alpine    | `3000`          | API REST Express                     |
| `frontend` | nginx Alpine         | `80`            | Angular compilado + reverse proxy    |

---

## Stack tecnológico

- **Frontend:** Angular 21, TypeScript, SCSS
- **Backend:** Node.js, Express 5, bcrypt, pg
- **Base de datos:** PostgreSQL 16
- **Servidor web / proxy:** nginx
- **Contenedores:** Docker, Docker Compose

---

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo
- Puertos `80` y `3000` disponibles en el host

---

## Cómo ejecutar

### 1. Ubicarse en la carpeta docker-bpmn

```bash
cd "generador de bpmn con ia/docker-bpmn"
```

### 2. Levantar con Docker Compose

```bash
docker compose up -d
```

La primera vez descarga las imágenes base y compila el frontend Angular (~1-2 minutos).

### 3. Abrir la aplicación

Ir a [http://localhost](http://localhost) en el navegador.

### 4. Credenciales de prueba

| Usuario     | Email               | Contraseña   | Rol     |
|-------------|---------------------|-------------|---------|
| Admin123    | admin@gmail.com     | admin123    | Admin   |
| Usuario123  | usuario@gmail.com   | usuario123  | Usuario |

---

## Comandos útiles

Todos los comandos deben ejecutarse desde la carpeta `docker-bpmn/`:

```bash
# Ver estado de los contenedores
docker compose ps

# Ver logs de todos los servicios
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f backend

# Detener todo
docker compose down

# Detener y eliminar volúmenes (borra la base de datos)
docker compose down -v

# Reconstruir imágenes (tras cambios en el código)
docker compose build
docker compose up -d
```

---

## Estructura del proyecto

```
generador de bpmn con ia/
├── docker-bpmn/                # Todos los archivos Docker y config
│   ├── docker-compose.yml      # Orquestación de servicios
│   ├── .env                    # Variables de entorno (BD)
│   ├── bpmn_script.sql         # Schema y datos iniciales de la BD
│   └── README.md               # Esta documentación
│
├── back-bpmn/                  # Backend Node.js
│   ├── Dockerfile              # Imagen del backend
│   ├── index.js                # Servidor Express y endpoints
│   ├── db.js                   # Conexión a PostgreSQL
│   └── package.json
│
└── front-bpmn/                 # Frontend Angular
    ├── Dockerfile              # Build multi-etapa: ng build → nginx
    ├── nginx.conf              # Config nginx con proxy a la API
    └── src/
        └── app/
            ├── core/services/  # AuthService (llamadas a la API)
            ├── features/
            │   ├── auth/       # Página de login
            │   ├── analisis/   # Generador BPMN
            │   └── admin/      # Gestión de usuarios (solo Admin)
            └── layout/         # Layout principal con navbar
```

---

## Endpoints de la API

| Método | Ruta                                  | Descripción                         |
|--------|---------------------------------------|-------------------------------------|
| POST   | `/api/login`                          | Iniciar sesión                      |
| POST   | `/api/register`                       | Registrar nuevo usuario             |
| GET    | `/api/users`                          | Listar todos los usuarios           |
| DELETE | `/api/users/:username`                | Eliminar un usuario                 |
| PUT    | `/api/users/:username`                | Actualizar datos de un usuario      |
| PUT    | `/api/users/profile-image/:username`  | Actualizar imagen de perfil         |

---

## Variables de entorno (.env)

El archivo `.env` en `docker-bpmn/` configura la base de datos:

```env
DB_USER=bpmn_user
DB_PASSWORD=bpmn_pass
DB_NAME=bpmn_db
```

Para producción, cambia estas credenciales por valores seguros.

---

## Cómo funciona el proxy nginx

El frontend Angular se compila como archivos estáticos y es servido por nginx. El mismo nginx actúa como reverse proxy:

- Peticiones a `/api/*` se reenvían al contenedor `backend` en el puerto 3000
- Peticiones a `/uploads/*` (imágenes de perfil) se reenvían también al backend
- Cualquier otra ruta devuelve `index.html`, permitiendo el enrutado del lado del cliente (SPA)

Esto permite que el frontend y la API sean accesibles desde el mismo dominio/puerto (80) sin problemas de CORS.
