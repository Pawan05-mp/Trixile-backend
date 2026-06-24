import os
import re
import pandas as pd
import json
import pathlib

def sanitise_name(name: str) -> str:
    name = name.lower().strip()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return name.strip("_")

def convert_dataset():
    excel_path = pathlib.Path(r"E:\New folder (3)\place-discovery\dataset\raw\Pondicherry_Enriched_v3.xlsx")
    output_dart_path = pathlib.Path(r"E:\New folder (3)\place-discovery\mobile\lib\shared\data\places_data.dart")
    
    if not excel_path.exists():
        print(f"Error: Enriched dataset not found at {excel_path}.")
        return

    print(f"Loading data from {excel_path}...")
    df = pd.read_excel(excel_path)
    print(f"Loaded {len(df)} records.")

    # Category name mappings
    name_map = {
        "quick_bite": "Quick Bite",
        "chill": "Chill Spot",
        "walk": "Scenic Walk",
        "fun": "Fun Activity",
        "peace": "Quiet & Peace"
    }

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

    dart_places = []

    for idx, row in df.iterrows():
        p_id = str(row.get("id"))
        if pd.isna(p_id) or not p_id.strip():
            p_id = f"p-{idx+1}"
            
        name = str(row.get("name")).strip()
        area = str(row.get("area", "Pondicherry")).strip()
        cat = str(row.get("category", "chill")).strip()
        
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
                # Extract tags from json-like list or comma separated string
                if str(tag_val).startswith("["):
                    try:
                        parsed = json.loads(str(tag_val).replace("'", '"'))
                        tags_raw.extend([t.strip().title() for t in parsed if t.strip()])
                    except Exception:
                        pass
                else:
                    tags_raw.extend([t.strip().title() for t in str(tag_val).split(",") if t.strip()])
        
        tags = list(set(tags_raw))

        # Thumbnail path or fallback
        thumb = row.get("thumbnail_url", "")
        # If it's a local assets path like "/assets/places/...", we use it, but since it will be loaded over network
        # or as an asset, we write it. If it doesn't start with /assets/ or http, fallback.
        if pd.notna(thumb) and (str(thumb).startswith("http") or str(thumb).startswith("/assets/")):
            image_urls = [str(thumb)]
        else:
            # check local file
            safe_name = sanitise_name(name)
            local_photo = pathlib.Path(r"E:\New folder (3)\place-discovery\assets\places") / f"{safe_name}.webp"
            if local_photo.exists():
                image_urls = [f"/assets/places/{safe_name}.webp"]
            else:
                image_urls = category_fallback_images.get(cat, category_fallback_images["quick_bite"])

        # Determine indoor/outdoor
        is_outdoor = "outdoor" in [t.lower() for t in tags] or cat in ["walk", "beach"]
        is_indoor = not is_outdoor or cat in ["quick_bite", "chill"]

        quality_score = float(row.get("quality_score")) if pd.notna(row.get("quality_score")) else 8.0
        popularity_score = float(row.get("popularity_score")) if pd.notna(row.get("popularity_score")) else 7.0

        phone = str(row.get("phone")) if pd.notna(row.get("phone")) and str(row.get("phone")).strip() else None
        website = str(row.get("google_maps_url")) if pd.notna(row.get("google_maps_url")) and str(row.get("google_maps_url")).strip() else None

        desc = f"A beautiful {name_map.get(cat, cat)} located in {area}, Pondicherry."

        # Format Dart list element
        image_urls_str = ", ".join([f"'{url}'" for url in image_urls])
        tags_str = ", ".join([f"'{tag}'" for tag in tags])

        phone_str = f"'{phone}'" if phone else "null"
        website_str = f"'{website}'" if website else "null"

        place_element = f"""  Place(
    id: '{p_id}',
    name: {repr(name)},
    description: {repr(desc)},
    categoryId: '{cat}',
    categoryName: '{name_map.get(cat, cat.replace("_", " ").title())}',
    area: {repr(area)},
    budgetLevel: {budget_level},
    qualityScore: {round(quality_score / 10.0, 2)},
    popularityIndex: {round(popularity_score / 10.0, 2)},
    latitude: {lat},
    longitude: {lng},
    imageUrls: [{image_urls_str}],
    tags: [{tags_str}],
    indoor: {'true' if is_indoor else 'false'},
    phoneNumber: {phone_str},
    websiteUrl: {website_str},
  )"""
        dart_places.append(place_element)

    # Write places_data.dart
    output_dart_path.parent.mkdir(parents=True, exist_ok=True)
    
    dart_content = f"""import '../models/place.dart';

final List<Place> realPlaces = [
{",\n".join(dart_places)}
];
"""
    output_dart_path.write_text(dart_content, encoding="utf-8")
    print(f"Successfully generated {output_dart_path} with {len(dart_places)} places.")

if __name__ == "__main__":
    convert_dataset()
