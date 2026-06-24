# Place Recommendation Backend API

High-performance recommendation backend built with FastAPI, PostgreSQL 17, PostGIS 3.5, and SQLAlchemy 2.x.

## Features

- **Date, Friends, and Solo Recommendations**: Compiles composite scores based on occasion weights using optimized SQL case-expressions.
- **Location-Aware Queries**: Uses PostGIS geography spatial indexes to retrieve places nearby using `ST_DWithin` in `<500ms`.
- **JWT Authentication**: User registration and login flow with secure password hashing (`bcrypt`) and session validation.
- **Favorites Management**: Save and retrieve favorite places, with automatic cascading.
- **Dockerized Architecture**: Simplified multi-container deployment using Docker Compose.
- **Automated Database Migrations**: Integrated database migration engine powered by Alembic.

---

## Getting Started

### Prerequisites

- **Docker** and **Docker Compose** installed on your system.

### Build and Run with Docker Compose

1. **Start the services**:
   Navigate to the root directory containing `docker-compose.yml` and run:
   ```bash
   docker compose up --build -d
   ```
   This will spin up:
   - `db` (PostGIS 3.5 database at `localhost:5432`)
   - `api` (FastAPI application at `localhost:8000`)

2. **Automatic Migrations**:
   The FastAPI lifespan automatically runs all Alembic migrations on startup, ensuring that the database tables (`users`, `places`, `favorites`) are created.

3. **Import Places Dataset**:
   After the services are up, seed/import the enriched place dataset:
   ```bash
   docker compose exec api python scripts/import_places.py
   ```
   This reads `Pondicherry_Enriched_v3.xlsx` from the container, parses geolocation coordinates to geography points, parses tags, and bulk upserts them with duplicate resolution.

---

## API Documentation

Once the backend is running, you can access the interactive OpenAPI documentation at:
- **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

### Core Endpoints

#### Health Check
- `GET /health` -> Returns `{"status": "ok"}`

#### Authentication
- `POST /auth/register` -> Register a new user (`email`, `password`, `name`)
- `POST /auth/login` -> Login to receive JWT token (Form data `username`, `password`)

#### Places
- `GET /places` -> Paginated list of places.
- `GET /places/{id}` -> Full detail of a place.
- `GET /places/search` -> Filter places by `name`, `category`, `area`, or `tag`.
- `GET /places/nearby` -> Return places within a radius of `distance_km` of coordinates `lat`, `lng`.

#### Recommendations
- `GET /places/recommendations` -> Highly optimized recommendation endpoint.
  - Parameters:
    - `occasion` (one of: `date`, `friends`, `solo`)
    - `lat` / `lng` (optional coordinate filter)
    - `distance_km` (optional radius limit)
    - `budget` (optional budget level filter)
    - `limit` (max number of recommendations)

#### Favorites (Authenticated)
- `POST /favorites` -> Add place to favorites.
- `DELETE /favorites/{id}` -> Remove place from favorites.
- `GET /favorites` -> List user's favorite places.
