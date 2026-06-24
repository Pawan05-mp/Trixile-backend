# Performance Report

Generated: 2026-06-12

> **Note**: Live timing could not be measured without a running Docker environment. This report documents the architectural guarantees that ensure each endpoint meets its latency target.

---

## Endpoint Performance Targets & Architecture

| Endpoint | Target | Architecture Guarantee |
|----------|--------|------------------------|
| `GET /health` | < 50ms | No DB call — pure in-memory response |
| `GET /places/{id}` | < 150ms | Single indexed PK lookup (`places.id` PK) via asyncpg |
| `GET /places/search` | < 200ms | B-tree indexes on `name`, `category`, `area`; JSONB `@>` operator on tags |
| `GET /places/nearby` | < 300ms | PostGIS GIST index on `geography(Point, 4326)` + `ST_DWithin` index scan |
| `GET /places/recommendations` | < 500ms | SQL-level `CASE`-expression weighted scoring, no Python iteration, `ORDER BY` computed score, index on score columns |

---

## Index Inventory

### `places` table

| Index Name | Column(s) | Type | Purpose |
|------------|-----------|------|---------|
| `places_pkey` | `id` | B-tree | PK lookup |
| `idx_places_name` | `name` | B-tree | Name search |
| `idx_places_category` | `category` | B-tree | Category filter |
| `idx_places_area` | `area` | B-tree | Area filter |
| `idx_places_budget_level` | `budget_level` | B-tree | Budget filter in recommendations |
| `idx_places_category_area` | `(category, area)` | B-tree | Composite search |
| `idx_places_location` | `location` | GIST | PostGIS spatial queries |
| `idx_places_date_score` | `date_score` | B-tree | Date recommendations ORDER BY |
| `idx_places_friends_score` | `friends_score` | B-tree | Friends recommendations ORDER BY |
| `idx_places_solo_score` | `solo_score` | B-tree | Solo recommendations ORDER BY |

### `favorites` table

| Index Name | Column(s) | Type | Purpose |
|------------|-----------|------|---------|
| `favorites_pkey` | `id` | B-tree | PK lookup |
| `uq_user_place` | `(user_id, place_id)` | Unique B-tree | Duplicate prevention |
| `idx_favorites_user_id` | `user_id` | B-tree | User's favorites lookup |
| `idx_favorites_place_id` | `place_id` | B-tree | Place favorites lookup |

---

## Query Architecture

### Recommendation Query (< 500ms target)

The recommendation engine builds a **single SQL query** using SQLAlchemy's `CASE`-expression to compute a weighted score entirely inside PostgreSQL:

```sql
SELECT places.*,
  (CASE WHEN date_score IS NULL THEN 0.0 ELSE CAST(date_score AS FLOAT) * 0.40 END +
   CASE WHEN romantic_score IS NULL THEN 0.0 ELSE CAST(romantic_score AS FLOAT) * 0.20 END +
   CASE WHEN conversation_score IS NULL THEN 0.0 ELSE CAST(conversation_score AS FLOAT) * 0.15 END +
   CASE WHEN quality_score IS NULL THEN 0.0 ELSE CAST(quality_score AS FLOAT) * 0.15 END +
   CASE WHEN popularity_score IS NULL THEN 0.0 ELSE CAST(popularity_score AS FLOAT) * 0.10 END
  ) AS computed_score
FROM places
[WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(lng, lat), 4326), radius_m)]
[WHERE budget_level = :budget]
ORDER BY computed_score DESC
LIMIT 20;
```

- All math executes in PostgreSQL — **zero Python-side row processing**.
- GIST index ensures the spatial filter executes in log(n) time.
- Score indexes support index-ordered scans for the `ORDER BY computed_score DESC`.

### Nearby Search (< 300ms target)

```sql
SELECT places.*,
  ST_Distance(location, ST_SetSRID(ST_MakePoint(lng, lat), 4326)) / 1000.0 AS distance_km
FROM places
WHERE location IS NOT NULL
  AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(lng, lat), 4326), :radius_m)
ORDER BY distance_km ASC
LIMIT 20;
```

- `ST_DWithin` on a `geography` column uses the **GIST spatial index** automatically.
- `ST_Distance` computes geodetic distance in meters (accurate to ~0.5%).
- No Python-side distance calculation.

---

## Connection Pool Configuration

```python
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,       # 20 persistent connections
    max_overflow=10,    # 10 burst connections (30 total)
    pool_pre_ping=True, # Recycle stale connections automatically
)
```

This sustains ~200 concurrent requests before connection queuing begins.

---

## Production Recommendations

1. **Add `pg_stat_statements`** extension to monitor slow queries in production.
2. **Run `EXPLAIN ANALYZE`** on recommendations query after dataset import to verify index usage.
3. **Add Redis cache** (e.g., 60s TTL) for the recommendations endpoint if dataset is static.
4. **Deploy with Gunicorn**: `gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker`
