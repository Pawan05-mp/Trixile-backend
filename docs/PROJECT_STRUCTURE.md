# Place Discovery - Project Structure

```
place-discovery/
|
+-- .env.example              # Environment variable template
+-- README.md                 # Project overview
|
+-- backend/                  # FastAPI back-end
|   +-- alembic/              # Database migrations (Alembic)
|   +-- app/
|   |   +-- api/
|   |   |   +-- routes/       # HTTP route handlers (auth, places, recommendations, favorites)
|   |   |   +-- dependencies.py
|   |   +-- core/             # Cross-cutting: config, logging, security, rate-limiter
|   |   +-- db/               # SQLAlchemy session & base model
|   |   +-- models/           # ORM models (Place, User, Favorite)
|   |   +-- repositories/    # Data-access layer
|   |   +-- schemas/          # Pydantic request/response schemas
|   |   +-- services/         # Business logic (auth, recommendations)
|   |   +-- main.py           # FastAPI application entry-point
|   +-- scripts/              # One-off helper scripts (import, photo rename)
|   +-- tests/                # Pytest test suite
|   +-- logs/                 # Runtime log files
|   +-- Dockerfile            # Container image definition
|   +-- requirements.txt      # Python dependencies
|   +-- alembic.ini           # Alembic configuration
|
+-- mobile/                   # Vite + React front-end
|   +-- src/
|   |   +-- components/       # React components (Map, PlaceCard, DeveloperDoc)
|   |   +-- data/             # Seed data (places.ts, categories.ts, tags.ts)
|   |   +-- services/         # API client helpers (auth, recommendation)
|   |   +-- App.tsx           # Root component
|   |   +-- main.tsx          # Vite entry point
|   |   +-- index.css         # Global styles
|   |   +-- types.ts          # TypeScript type definitions
|   +-- index.html            # HTML shell
|   +-- package.json          # npm dependencies & scripts
|   +-- vite.config.ts        # Vite build configuration
|   +-- tsconfig.json         # TypeScript configuration
|
+-- dataset/                  # Data files & enrichment tooling
|   +-- raw/                  # Original Excel datasets
|   +-- processed/            # Cleaned / transformed data (future)
|   +-- reports/              # Data-quality reports (future)
|   +-- enrichment/           # Enrichment scripts & configs
|       +-- enrich.py         # Main enrichment pipeline
|       +-- convert_to_ts.py  # Excel -> TypeScript converter
|       +-- category_baselines.json
|       +-- enrichment_report.json
|
+-- assets/                   # Static media
|   +-- places/               # 215 place thumbnail images (.webp)
|
+-- docs/                     # Documentation & reports
|   +-- PROJECT_STRUCTURE.md  # This file
|   +-- runtime_report.md
|   +-- performance_report.md
|   +-- production_readiness.md
|   +-- coverage.json
|   +-- import_report.json
|
+-- infra/                    # Infrastructure & deployment
    +-- docker/               # docker-compose.yml
    +-- deployment/           # CI/CD configs (future)
    +-- nginx/                # Reverse-proxy configs (future)
```

## Folder Purposes

| Folder | Purpose |
|--------|---------|
| `backend/` | FastAPI REST API with PostgreSQL/PostGIS, Alembic migrations, and pytest tests. |
| `mobile/` | Vite + React (TypeScript) web front-end for place discovery UI. |
| `dataset/` | Raw Excel datasets, enrichment scripts, and data-quality tooling. |
| `assets/` | Place thumbnail images (.webp), named by sanitised place name. |
| `docs/` | All project documentation, reports, and metrics. |
| `infra/` | Docker Compose, deployment scripts, and nginx configuration. |
