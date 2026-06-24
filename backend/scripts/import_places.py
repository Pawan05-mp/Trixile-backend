"""Import enriched places from Excel file to PostGIS database with batching, validation, and error isolation."""

import os
import sys
import uuid
import json
import logging
import argparse
import asyncio
import pandas as pd
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

# Add backend directory to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import async_session_factory
from app.models.place import Place

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("import_places")


def parse_tags(tags_val) -> list[str]:
    """Parse comma-separated string or list/JSON into a clean list of strings."""
    if tags_val is None:
        return []
    if isinstance(tags_val, list):
        return [str(t).strip() for t in tags_val if pd.notna(t) and str(t).strip()]
    if isinstance(tags_val, str):
        return [t.strip() for t in tags_val.split(",") if t.strip()]
    try:
        if pd.isna(tags_val) or not tags_val:
            return []
    except (ValueError, TypeError):
        pass
    return []



def to_float(val) -> float | None:
    """Coerce value to float or return None."""
    if pd.isna(val) or val == "":
        return None
    try:
        return float(val)
    except (TypeError, ValueError):
        return None


def to_int(val) -> int | None:
    """Coerce value to int or return None."""
    if pd.isna(val) or val == "":
        return None
    try:
        return int(float(val))
    except (TypeError, ValueError):
        return None


def validate_row(row_idx: int, row_data: dict) -> list[str]:
    """Validate raw row data and return a list of error messages."""
    errors = []
    
    # Validate Name
    name = row_data.get("name")
    if pd.isna(name) or not str(name).strip():
        errors.append("Name is required and cannot be empty")
        
    # Validate Lat/Lng
    lat = to_float(row_data.get("lat"))
    lng = to_float(row_data.get("lng"))
    if lat is not None and (lat < -90.0 or lat > 90.0):
        errors.append(f"Latitude ({lat}) out of range [-90, 90]")
    if lng is not None and (lng < -180.0 or lng > 180.0):
        errors.append(f"Longitude ({lng}) out of range [-180, 180]")
        
    # Validate rating
    rating = to_float(row_data.get("rating"))
    if rating is not None and (rating < 0.0 or rating > 5.0):
        errors.append(f"Rating ({rating}) out of range [0, 5]")
        
    # Validate reviews
    reviews = to_int(row_data.get("reviews"))
    if reviews is not None and reviews < 0:
        errors.append(f"Reviews ({reviews}) cannot be negative")
        
    return errors


async def insert_single_record(session: AsyncSession, place_data: dict) -> bool:
    """Insert or update a single record in a subtransaction."""
    try:
        stmt = insert(Place).values(place_data)
        update_dict = {
            c.name: stmt.excluded[c.name]
            for c in Place.__table__.columns
            if c.name not in ["id", "created_at"]
        }
        stmt = stmt.on_conflict_do_update(
            constraint="places_pkey",
            set_=update_dict
        )
        await session.execute(stmt)
        return True
    except Exception as e:
        logger.error(f"Failed to insert record {place_data.get('name')}: {e}")
        return False


async def import_data(file_path: str, batch_size: int = 100) -> dict:
    """Import dataset from Excel into PostgreSQL with batching and validation."""
    if not os.path.exists(file_path):
        logger.error(f"Excel file not found at: {file_path}")
        sys.exit(1)

    logger.info(f"Loading data from {file_path}...")
    try:
        df = pd.read_excel(file_path)
    except Exception as e:
        logger.error(f"Failed to read Excel file: {e}")
        sys.exit(1)

    total_records = len(df)
    logger.info(f"Loaded {total_records} records. Starting import in batches of {batch_size}...")

    successful_count = 0
    failed_count = 0
    errors_log = []

    # Keep track of active batch
    batch_records = []
    
    async with async_session_factory() as session:
        for idx, row in df.iterrows():
            row_idx = int(idx) + 1
            row_dict = row.to_dict()
            
            # 1. Validate Row Data
            row_errors = validate_row(row_idx, row_dict)
            if row_errors:
                failed_count += 1
                errors_log.append({
                    "row": row_idx,
                    "name": str(row_dict.get("name", "Unknown")),
                    "errors": row_errors
                })
                logger.warning(f"Row {row_idx} skipped due to validation errors: {', '.join(row_errors)}")
                continue
                
            # 2. Extract Coordinates / Geography
            lat = to_float(row_dict.get("lat"))
            lng = to_float(row_dict.get("lng"))
            location_wkt = f"POINT({lng} {lat})" if (lat is not None and lng is not None) else None

            # 3. Determine Place ID (UUID)
            raw_id = row_dict.get("id")
            if pd.isna(raw_id) or not raw_id:
                place_uuid = uuid.uuid4()
            else:
                raw_id_str = str(raw_id).strip()
                try:
                    place_uuid = uuid.UUID(raw_id_str)
                except ValueError:
                    place_uuid = uuid.uuid5(uuid.NAMESPACE_DNS, raw_id_str)

            # 4. Map Attributes
            place_data = {
                "id": place_uuid,
                "name": str(row_dict.get("name", "")).strip(),
                "category": str(row_dict.get("category", "")).strip() if pd.notna(row_dict.get("category")) else None,
                "area": str(row_dict.get("area", "")).strip() if pd.notna(row_dict.get("area")) else None,
                "rating": to_float(row_dict.get("rating")),
                "reviews": to_int(row_dict.get("reviews")),
                "budget_level": str(row_dict.get("budget_level", "")).strip() if pd.notna(row_dict.get("budget_level")) else None,
                "latitude": lat,
                "longitude": lng,
                "location": location_wkt,
                "date_score": to_float(row_dict.get("date_score")),
                "friends_score": to_float(row_dict.get("friends_score")),
                "solo_score": to_float(row_dict.get("solo_score")),
                "romantic_score": to_float(row_dict.get("romantic_score")),
                "conversation_score": to_float(row_dict.get("conversation_score")),
                "quiet_score": to_float(row_dict.get("quiet_score")),
                "scenic_score": to_float(row_dict.get("scenic_score")),
                "social_score": to_float(row_dict.get("social_score")),
                "activity_score": to_float(row_dict.get("activity_score")),
                "comfort_score": to_float(row_dict.get("comfort_score")),
                "nature_score": to_float(row_dict.get("nature_score")),
                "stimulation_score": to_float(row_dict.get("stimulation_score")),
                "photo_score": to_float(row_dict.get("photo_score")),
                "quality_score": to_float(row_dict.get("quality_score")),
                "popularity_score": to_float(row_dict.get("popularity_score")),
                "recommendation_score": to_float(row_dict.get("recommendation_score")),
                "occasion_tags": parse_tags(row_dict.get("occasion_tags")),
                "atmosphere_tags": parse_tags(row_dict.get("atmosphere_tags")),
                "best_visit_time": str(row_dict.get("best_visit_time", "")).strip() if pd.notna(row_dict.get("best_visit_time")) else None,
                "opening_time": str(row_dict.get("opening_time", "")).strip() if pd.notna(row_dict.get("opening_time")) else None,
                "closing_time": str(row_dict.get("closing_time", "")).strip() if pd.notna(row_dict.get("closing_time")) else None,
                "google_maps_url": str(row_dict.get("google_maps_url", "")).strip() if pd.notna(row_dict.get("google_maps_url")) else None,
                "thumbnail_url": str(row_dict.get("thumbnail_url", "")).strip() if pd.notna(row_dict.get("thumbnail_url")) else None,
                "detail_url": str(row_dict.get("detail_url", "")).strip() if pd.notna(row_dict.get("detail_url")) else None,
            }
            
            batch_records.append(place_data)
            
            # 5. Flush batch if full
            if len(batch_records) >= batch_size:
                succeeded, failed, errs = await process_batch(session, batch_records)
                successful_count += succeeded
                failed_count += failed
                errors_log.extend(errs)
                batch_records.clear()
                
        # 6. Process remaining records in final batch
        if batch_records:
            succeeded, failed, errs = await process_batch(session, batch_records)
            successful_count += succeeded
            failed_count += failed
            errors_log.extend(errs)
            
        await session.commit()

    report = {
        "total_records": total_records,
        "successful_records": successful_count,
        "failed_records": failed_count,
        "errors": errors_log
    }

    report_path = "import_report.json"
    try:
        with open(report_path, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
        logger.info(f"Import report written to {report_path}")
    except Exception as e:
        logger.error(f"Failed to write import report: {e}")

    logger.info(f"Import process completed: {successful_count} succeeded, {failed_count} failed.")
    return report


async def process_batch(session: AsyncSession, batch: list[dict]) -> tuple[int, int, list]:
    """Execute a batch of records. Fallback to individual rows on exception."""
    try:
        # Create nested transaction point
        async with session.begin_nested():
            # SQLAlchemy bulk insert with on_conflict_do_update
            stmt = insert(Place)
            update_dict = {
                c.name: stmt.excluded[c.name]
                for c in Place.__table__.columns
                if c.name not in ["id", "created_at"]
            }
            stmt = stmt.on_conflict_do_update(
                constraint="places_pkey",
                set_=update_dict
            )
            # Execute with batch values
            await session.execute(stmt, batch)
        return len(batch), 0, []
    except Exception as e:
        logger.warning("Batch insert failed due to database constraint/error. Falling back to row-by-row isolation...")
        # Since it failed, we must isolate failures row-by-row
        succeeded = 0
        failed = 0
        errors = []
        
        for item in batch:
            async with session.begin_nested():
                ok = await insert_single_record(session, item)
                if ok:
                    succeeded += 1
                else:
                    failed += 1
                    errors.append({
                        "row": "Isolated Batch Failure",
                        "name": item.get("name"),
                        "errors": ["Database integrity / write constraint failure"]
                    })
        return succeeded, failed, errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Import enriched places Excel into database.")
    parser.add_argument(
        "--file", 
        type=str, 
        default="Pondicherry_Enriched_v3.xlsx",
        help="Path to the Excel file containing enriched places."
    )
    args = parser.parse_args()
    
    # Check if file exists relative to backend or root
    target_file = args.file
    if not os.path.exists(target_file):
        # Try parent directory since this script runs from backend/scripts/
        parent_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), target_file)
        if os.path.exists(parent_path):
            target_file = parent_path

    asyncio.run(import_data(target_file))
