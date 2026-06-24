import os
import re
import pandas as pd
import numpy as np
import json

def convert_dataset():
    excel_path = "Pondicherry_Enriched_v3.xlsx"
    if not os.path.exists(excel_path):
        print(f"Error: Enriched dataset {excel_path} not found.")
        return

    df = pd.read_excel(excel_path)
    print(f"Loaded {len(df)} records from {excel_path}.")

    # 1. Map categories to frontend formats
    unique_cats = df["category"].dropna().unique().tolist()
    # Icon mapping for the categories
    icon_map = {
        "quick_bite": "Coffee",
        "chill": "Utensils",
        "walk": "Waves",
        "fun": "Compass",
        "peace": "Heart"
    }
    name_map = {
        "quick_bite": "Quick Bite",
        "chill": "Chill Spot",
        "walk": "Scenic Walk",
        "fun": "Fun Activity",
        "peace": "Quiet & Peace"
    }

    categories_list = []
    for cat in unique_cats:
        name = name_map.get(cat, cat.replace("_", " ").title())
        icon = icon_map.get(cat, "Sparkles")
        categories_list.append({
            "id": cat,
            "name": name,
            "icon": icon
        })

    # Write categories.ts
    categories_ts_content = f"""/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import {{ Category }} from '../types';

export const CATEGORIES: Category[] = {json.dumps(categories_list, indent=2)};
"""
    with open("src/data/categories.ts", "w", encoding="utf-8") as f:
        f.write(categories_ts_content)
    print("Updated src/data/categories.ts")

    # 2. Extract Area Centers
    area_centers = {}
    for area, group in df.groupby("area"):
        if pd.isna(area) or not str(area).strip():
            continue
        lat_avg = float(group["lat"].dropna().mean()) if not group["lat"].dropna().empty else 11.9401
        lng_avg = float(group["lng"].dropna().mean()) if not group["lng"].dropna().empty else 79.8278
        area_centers[str(area).strip()] = {
            "lat": round(lat_avg, 4),
            "lng": round(lng_avg, 4)
        }

    # 3. Assemble Places
    places_list = []
    category_fallback_images = {
        "quick_bite": [
            "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600",
            "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&q=80&w=600"
        ],
        "chill": [
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=600",
            "https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&q=80&w=600"
        ],
        "walk": [
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=600",
            "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&q=80&w=600"
        ],
        "fun": [
            "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&q=80&w=600",
            "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?auto=format&fit=crop&q=80&w=600"
        ],
        "peace": [
            "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&q=80&w=600",
            "https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&q=80&w=600"
        ]
    }

    for idx, row in df.iterrows():
        p_id = str(row.get("id"))
        name = str(row.get("name")).strip()
        area = str(row.get("area")).strip()
        cat = str(row.get("category")).strip()
        
        lat = float(row.get("lat")) if pd.notna(row.get("lat")) else 11.9401
        lng = float(row.get("lng")) if pd.notna(row.get("lng")) else 79.8278
        
        # Normalize budget cost (1 to 4 tier)
        b_val = int(row.get("budget_level")) if pd.notna(row.get("budget_level")) else 2
        if b_val <= 1:
            budget_level = 1
        elif b_val <= 3:
            budget_level = 2
        elif b_val <= 5:
            budget_level = 3
        else:
            budget_level = 4

        # Parse tags lists
        tags_raw = []
        for tag_col in ["occasion_tags", "atmosphere_tags"]:
            tag_val = row.get(tag_col)
            if pd.notna(tag_val) and str(tag_val).strip():
                tags_raw.extend([t.strip().title() for t in str(tag_val).split(",") if t.strip()])
        # Deduplicate tags
        tags = list(set(tags_raw))

        # Best time to visit description
        best_time = str(row.get("best_visit_time")) if pd.notna(row.get("best_visit_time")) else "Evening"
        open_time = str(row.get("opening_time")) if pd.notna(row.get("opening_time")) else ""
        close_time = str(row.get("closing_time")) if pd.notna(row.get("closing_time")) else ""
        if open_time and close_time:
            best_time = f"{best_time} ({open_time} - {close_time})"

        # Thumbnail or Fallbacks
        img_url = str(row.get("thumbnail_url")).strip() if pd.notna(row.get("thumbnail_url")) else ""
        if img_url and img_url.startswith("http"):
            image_urls = [img_url]
        else:
            image_urls = category_fallback_images.get(cat, category_fallback_images["quick_bite"])

        # Determine indoor/outdoor orientation
        is_outdoor = "outdoor" in [t.lower() for t in tags] or cat in ["walk", "beach"]
        is_indoor = not is_outdoor or cat in ["quick_bite", "chill"]

        # Quality & Popularity scores (normalize from 1-10 down to 0.0-1.0)
        quality_score = float(row.get("quality_score")) if pd.notna(row.get("quality_score")) else 8.0
        popularity_score = float(row.get("popularity_score")) if pd.notna(row.get("popularity_score")) else 7.0
        
        place_data = {
            "id": p_id,
            "name": name,
            "description": f"A beautiful {name_map.get(cat, cat)} located in {area}, Pondicherry. Enjoy curated features and a harmonized experience.",
            "area": area,
            "latitude": lat,
            "longitude": lng,
            "budgetLevel": budget_level,
            "bestTime": best_time,
            "categoryId": cat,
            "qualityScore": round(quality_score / 10.0, 2),
            "popularityScore": round(popularity_score / 10.0, 2),
            "romanticScore": int(row.get("romantic_score")) if pd.notna(row.get("romantic_score")) else 5,
            "quietScore": int(row.get("quiet_score")) if pd.notna(row.get("quiet_score")) else 5,
            "socialScore": int(row.get("social_score")) if pd.notna(row.get("social_score")) else 5,
            "activityScore": int(row.get("activity_score")) if pd.notna(row.get("activity_score")) else 5,
            "scenicScore": int(row.get("scenic_score")) if pd.notna(row.get("scenic_score")) else 5,
            "sadScore": 0.0,
            "heartbrokenScore": 0.0,
            "lonelyScore": 0.0,
            "anxiousScore": 0.0,
            "angryScore": 0.0,
            "numbScore": 0.0,
            "imageUrls": image_urls,
            "tags": tags,
            "createdAt": str(row.get("created_at")) if pd.notna(row.get("created_at")) else "2026-06-12T00:00:00.000Z",
            "indoor": is_indoor,
            "outdoor": is_outdoor
        }
        places_list.append(place_data)

    # Write places.ts
    places_ts_content = f"""/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import {{ Place }} from '../types';

export const AREA_CENTERS: Record<string, {{ lat: number; lng: number }}> = {json.dumps(area_centers, indent=2)};

export const SEED_PLACES: Place[] = {json.dumps(places_list, indent=2)};
"""
    with open("src/data/places.ts", "w", encoding="utf-8") as f:
        f.write(places_ts_content)
    print(f"Updated src/data/places.ts with {len(places_list)} Pondicherry places.")

if __name__ == "__main__":
    convert_dataset()
