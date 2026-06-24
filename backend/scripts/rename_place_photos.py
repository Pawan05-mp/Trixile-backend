import json
import pathlib
import re
import sys
import urllib.request
import pandas as pd
from typing import List, Dict

# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------
def sanitise_name(name: str) -> str:
    """
    Turn a place name into a safe filename.
    Example: "A1 beef  World" → "a1_beef_world"
    """
    name = name.lower().strip()
    name = re.sub(r"[^a-z0-9]+", "_", name)   # non‑alphanum → _
    return name.strip("_")

def find_existing_image(folder: pathlib.Path, base_name: str) -> pathlib.Path | None:
    """Look for any file in *folder* that already contains *base_name*."""
    if not folder.exists():
        return None
    pattern = re.compile(re.escape(base_name), re.IGNORECASE)
    for f in folder.iterdir():
        if f.is_file() and pattern.search(f.stem):
            return f
    return None

def download_image(url: str, dest: pathlib.Path) -> None:
    """Download the image from Unsplash and save it as a .webp."""
    with urllib.request.urlopen(url) as resp:
        data = resp.read()
    dest.write_bytes(data)

# ----------------------------------------------------------------------
# Main routine
# ----------------------------------------------------------------------
def main() -> None:
    excel_file = pathlib.Path(r"E:\New folder (3)\place-discovery\dataset\raw\Pondicherry_Enriched_v3.xlsx")
    dest_photo_dir = pathlib.Path(r"E:\New folder (3)\place-discovery\assets\places")
    input_photo_dir = pathlib.Path(r"E:\New folder (3)\BulkResizePhotos.com")
    
    if not excel_file.is_file():
        sys.exit(f"Error: Excel dataset not found at {excel_file}")
    
    dest_photo_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Loading dataset from {excel_file}...")
    df = pd.read_excel(excel_file)
    df["thumbnail_url"] = df["thumbnail_url"].astype(object)
    
    updated = 0
    
    for idx, row in df.iterrows():
        name = row.get("name", "")
        if pd.isna(name) or not str(name).strip():
            continue
        
        name = str(name).strip()
        safe_name = sanitise_name(name)
        target_file = dest_photo_dir / f"{safe_name}.webp"
        
        # 1. Try to find the image in assets/places first
        if target_file.exists():
            # Image already exists in final assets folder
            rel_path = f"/assets/places/{target_file.name}"
            df.at[idx, "thumbnail_url"] = rel_path
            updated += 1
            continue
            
        # 2. Try to find the image in BulkResizePhotos.com
        existing_input = find_existing_image(input_photo_dir, safe_name)
        if existing_input:
            # Copy and rename to target
            target_file.write_bytes(existing_input.read_bytes())
            print(f"[COPY/RENAME] Move {existing_input.name} -> assets/places/{target_file.name}")
            rel_path = f"/assets/places/{target_file.name}"
            df.at[idx, "thumbnail_url"] = rel_path
            updated += 1
        else:
            # 3. Download the Unsplash image if present
            # Excel might store imageUrls as a string representation of list or raw URL
            img_urls_val = row.get("imageUrls", "[]")
            # Fallback to checking the thumbnail_url column if it's already an unsplash link
            existing_url = row.get("thumbnail_url", "")
            
            url_to_download = None
            if pd.notna(existing_url) and str(existing_url).startswith("http"):
                url_to_download = str(existing_url)
            else:
                try:
                    # try to parse as JSON list
                    urls = json.loads(img_urls_val)
                    if urls and isinstance(urls, list):
                        url_to_download = urls[0]
                except Exception:
                    # fallback to raw string if it starts with http
                    if pd.notna(img_urls_val) and str(img_urls_val).startswith("http"):
                        url_to_download = str(img_urls_val)
            
            if url_to_download:
                try:
                    download_image(url_to_download, target_file)
                    print(f"[DOWNLOAD] Image for '{name}' saved to assets/places/{target_file.name}")
                    rel_path = f"/assets/places/{target_file.name}"
                    df.at[idx, "thumbnail_url"] = rel_path
                    updated += 1
                except Exception as exc:
                    print(f"Warning: Failed to download image for '{name}': {exc}")
            else:
                print(f"Warning: No image source found for '{name}'. Skipping.")

    # Write the updated dataset back to the Excel file
    print(f"Saving updated dataset to {excel_file}...")
    df.to_excel(excel_file, index=False)
    print(f"\n[DONE] Finished - updated thumbnail_url for {updated} place(s).")

if __name__ == "__main__":
    main()