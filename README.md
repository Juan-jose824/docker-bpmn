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
│  - Autenticación JWT (access + refresh token)       │
│  - CRUD de usuarios                                 │
│  - Imágenes de perfil                               │
│  - Puente hacia ai-service                          │
└──────────────┬──────────────────┬───────────────────┘
               │                  │
┌──────────────▼──────┐  ┌────────▼────────────────────┐
│  PostgreSQL 16      │  │  ai-service Node.js (4000)  │
│  - Tabla users      │  │  - Extracción de texto PDF   │
│  - Tabla ai_analysis│  │  - Integración Gemini AI     │
│  - Datos semilla    │  │  - Generación BPMN XML       │
└─────────────────────┘  │  - Integración OpenClaw      │
                         └────────────┬────────────────┘
                                      │
                         ┌────────────▼────────────────┐
                         │  openclaw (puerto 3333)      │
                         │  - Agente IA auxiliar        │
                         │  - Detección de procesos     │
                         └─────────────────────────────┘
```

### Servicios Docker

| Servicio      | Imagen                | Puerto expuesto | Descripción                                  |
|---------------|----------------------|-----------------|----------------------------------------------|
| `db`          | `postgres:16-alpine` | interno         | Base de datos PostgreSQL                     |
| `backend`     | Node.js 22 Alpine    | `3000`          | API REST Express con JWT                     |
| `frontend`    | nginx Alpine         | `80`            | Angular compilado + reverse proxy            |
| `ai-service`  | Node.js Alpine       | `4000`          | Servicio de IA: análisis PDF y generación BPMN |
| `openclaw`    | openclaw:latest      | `3333`          | Agente IA auxiliar para detección de procesos |

---

## Stack tecnológico

- **Frontend:** Angular 21, TypeScript, SCSS
- **Backend:** Node.js, Express 5, bcrypt, pg, jsonwebtoken, axios
- **Base de datos:** PostgreSQL 16
- **Servidor web / proxy:** nginx
- **Contenedores:** Docker, Docker Compose
- **IA principal:** Google Gemini 2.5 Flash (via `@google/generative-ai`)
- **IA auxiliar:** OpenClaw (agente LLM local)
- **Extracción PDF:** pdf-parse

---

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo
- Puertos `80`, `3000`, `4000` y `3333` disponibles en el host
- **API Key de Google Gemini** (requerida para la generación de BPMN)

---

## Cómo ejecutar

### 1. Ubicarse en la carpeta docker-bpmn

```bash
cd "generador de bpmn con ia/docker-bpmn"
```

### 2. Configurar la API Key de Gemini

Edita el archivo `.env` y establece tu clave de Google Gemini:

```env
GEMINI_API_KEY=tu_api_key_aqui
```

> Puedes obtener una API Key gratuita en [Google AI Studio](https://aistudio.google.com/app/apikey).

### 3. Levantar con Docker Compose

```bash
docker compose up -d
```

La primera vez descarga las imágenes base y compila el frontend Angular (~1-2 minutos).

### 4. Abrir la aplicación

Ir a [http://localhost](http://localhost) en el navegador.

### 5. Credenciales de prueba

| Usuario     | Email               | Contraseña   | Rol     |
|-------------|---------------------|-------------|---------|
| Admin123    | admin@gmail.com     | admin123    | Admin   |
| Usuario123  | usuario@gmail.com   | usuario123  | Usuario |

---

## Cómo usar el Generador de BPMN

1. **Inicia sesión** con cualquiera de las credenciales de prueba.
2. Dirígete al módulo **Análisis / Generador BPMN**.
3. **Sube un archivo PDF** con el manual o documento de procesos que deseas analizar.
4. El sistema extrae el texto del PDF y lo envía al servicio de IA.
5. **Gemini 2.5 Flash** analiza el manual y genera la estructura del diagrama BPMN.
6. El `ai-service` convierte la estructura en **XML BPMN 2.0** válido para Bizagi.
7. Puedes **descargar el archivo `.bpmn`** y abrirlo directamente en [Bizagi Modeler](https://www.bizagi.com/es/plataforma/modeler).

### Límites del análisis

| Parámetro          | Valor        |
|--------------------|--------------|
| Tamaño máximo PDF  | 50 MB        |
| Texto analizado    | 280,000 chars |
| Tokens de salida   | 65,536       |
| Tiempo de espera   | 3 minutos    |
| Modelo IA          | gemini-2.5-flash |

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
docker compose logs -f ai-service
docker compose logs -f openclaw

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
│   ├── .env                    # Variables de entorno (BD + IA)
│   ├── bpmn_script.sql         # Schema y datos iniciales de la BD
│   └── README.md               # Esta documentación
│
├── back-bpmn/                  # Backend Node.js
│   ├── Dockerfile              # Imagen del backend
│   ├── index.js                # Servidor Express y endpoints
│   ├── db.js                   # Conexión a PostgreSQL
│   └── package.json
│
├── ai-service/                 # Servicio de IA
│   ├── Dockerfile              # Imagen del servicio IA
│   ├── index.js                # Servidor Express, integración Gemini y generación BPMN
│   ├── package.json
│   ├── openclaw/
│   │   └── client.js           # Cliente HTTP para OpenClaw
│   └── services/
│       └── processDetection.js # Detección de procesos con OpenClaw
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

### Autenticación

| Método | Ruta                | Descripción                        |
|--------|---------------------|------------------------------------|
| POST   | `/api/login`        | Iniciar sesión (devuelve JWT)       |
| POST   | `/api/register`     | Registrar nuevo usuario             |
| POST   | `/api/refresh`      | Renovar access token                |
| POST   | `/api/logout`       | Cerrar sesión                       |

### Usuarios

| Método | Ruta                                  | Descripción                         |
|--------|---------------------------------------|-------------------------------------|
| GET    | `/api/users`                          | Listar todos los usuarios           |
| DELETE | `/api/users/:username`                | Eliminar un usuario                 |
| PUT    | `/api/users/:username`                | Actualizar datos de un usuario      |
| PUT    | `/api/users/profile-image/:username`  | Actualizar imagen de perfil         |

### Inteligencia Artificial

| Método | Ruta                | Descripción                                              | Autenticación |
|--------|---------------------|----------------------------------------------------------|---------------|
| POST   | `/api/ai/analyze`   | Recibe PDF, lo reenvía al ai-service y retorna BPMN XML  | JWT requerido |

### ai-service (interno, puerto 4000)

| Método | Ruta       | Descripción                                              |
|--------|------------|----------------------------------------------------------|
| POST   | `/analyze` | Extrae texto del PDF, llama a Gemini y genera BPMN XML   |

---

## Servicio de IA (`ai-service`)

El `ai-service` es el núcleo del generador BPMN. Su flujo de trabajo es:

1. **Recibe el PDF** vía multipart/form-data (máx. 50 MB).
2. **Extrae el texto** del PDF con `pdf-parse`.
3. Si el PDF es mayor a 500 KB, lo sube a la **Gemini File API** para mejor análisis.
4. **Construye un prompt** detallado con reglas de modelado BPMN profesional.
5. Envía el prompt a **Gemini 2.5 Flash** y obtiene un JSON estructurado.
6. Si la respuesta fue truncada, hace una **segunda llamada** para completarla.
7. Aplica una serie de **FIX automáticos** al JSON (nodos huérfanos, ciclos, roles inválidos, etc.).
8. **Genera el XML BPMN 2.0** con layouts automáticos de pools, lanes, shapes y edges.
9. Devuelve el XML listo para importar en **Bizagi Modeler**.

### Tipos de nodo BPMN generados

| Tipo                      | Descripción                                              |
|---------------------------|----------------------------------------------------------|
| `startEvent`              | Inicio del proceso                                       |
| `endEvent`                | Fin simple (errores, cancelaciones)                      |
| `endEventMessage`         | Fin con confirmación visible al usuario                  |
| `endEventTerminate`       | Fin que cierra toda la sesión                            |
| `endEventSignal`          | Fin que notifica a un sistema externo                    |
| `userTask`                | Acción ejecutada por el usuario en pantalla              |
| `serviceTask`             | Llamada automática a API externa (SAJ, RENAPO, etc.)     |
| `scriptTask`              | Validación interna del sistema sin interacción           |
| `exclusiveGateway`        | Decisión con 2 o más caminos (con condiciones)           |
| `intermediateEvent`       | Conector entre lanes/secciones                           |
| `intermediateEventMessage`| Notificación dentro del flujo (el proceso continúa)      |
| `intermediateEventMultiple`| Hub del menú principal (distribuye a varios módulos)    |

### OpenClaw (agente auxiliar)

El servicio también integra **OpenClaw**, un agente IA local que puede:
- Analizar el manual y extraer módulos, roles, sistemas y APIs.
- Detectar procesos de negocio independientes dentro del documento.

OpenClaw se usa de forma complementaria a Gemini y su uso es opcional (falla silenciosamente si no está disponible).

---

## Base de datos

### Esquema

```sql
-- Tabla de usuarios
CREATE TABLE users (
    id_user        SERIAL PRIMARY KEY,
    user_name      VARCHAR(50) UNIQUE NOT NULL,
    email          VARCHAR(100) UNIQUE NOT NULL,
    pass           TEXT NOT NULL,
    rol            VARCHAR(20) NOT NULL DEFAULT 'Usuario',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    profile_image  TEXT
);

-- Tabla de análisis IA
CREATE TABLE ai_analysis (
    id_analysis    SERIAL PRIMARY KEY,
    id_user        INTEGER REFERENCES users(id_user) ON DELETE CASCADE,
    file_name      VARCHAR(255) NOT NULL,
    markdown_content TEXT,
    bpmn_xml       TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Roles de usuario

| Rol      | Permisos                                                   |
|----------|------------------------------------------------------------|
| `Admin`  | Acceso total: gestión de usuarios, análisis BPMN           |
| `Usuario`| Acceso a análisis BPMN, no puede gestionar usuarios        |

---

## Variables de entorno (.env)

El archivo `.env` en `docker-bpmn/` configura todos los servicios:

```env
# Base de datos
DB_USER=bpmn_user
DB_PASSWORD=bpmn_pass
DB_NAME=bpmn_db

# Inteligencia Artificial (requerida)
GEMINI_API_KEY=tu_api_key_de_google_gemini
```

> ⚠️ Para producción, cambia todas estas credenciales por valores seguros y nunca subas el `.env` al repositorio.

Las siguientes variables son opcionales y están preparadas para uso futuro:

```env
# ANTHROPIC_API_KEY=  # Para integrar con Claude de Anthropic
```

---

## Cómo funciona el proxy nginx

El frontend Angular se compila como archivos estáticos y es servido por nginx. El mismo nginx actúa como reverse proxy:

- Peticiones a `/api/*` se reenvían al contenedor `backend` en el puerto 3000
- Peticiones a `/uploads/*` (imágenes de perfil) se reenvían también al backend
- Cualquier otra ruta devuelve `index.html`, permitiendo el enrutado del lado del cliente (SPA)

Esto permite que el frontend y la API sean accesibles desde el mismo dominio/puerto (80) sin problemas de CORS.

---

## Autenticación JWT

El backend utiliza un esquema de doble token:

- **Access Token:** duración de 8 horas, enviado en el header `Authorization: Bearer <token>`.
- **Refresh Token:** duración de 8 horas, almacenado en cookie HttpOnly.

Todas las rutas protegidas (incluyendo `/api/ai/analyze`) requieren el access token válido.