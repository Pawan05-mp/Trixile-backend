import pathlib
import re
import sys
import pandas as pd

# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------
def sanitise_name(name: str) -> str:
    """
    Convert a place name into the filename used for the thumbnail.
    Example: "A1 beef  World" → "a1_beef_world"
    """
    name = name.lower().strip()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return name.strip("_")

# ----------------------------------------------------------------------
# Main routine
# ----------------------------------------------------------------------
def main() -> None:
    excel_file = pathlib.Path(r"E:\New folder (3)\place-discovery\dataset\raw\Pondicherry_Enriched_v3.xlsx")
    photo_root = pathlib.Path(r"E:\New folder (3)\place-discovery\assets\places")

    if not excel_file.is_file():
        sys.exit(f"Error: Excel dataset not found at {excel_file}")

    if not photo_root.is_dir():
        sys.exit(f"Error: Photo folder not found at {photo_root}")

    print(f"Loading dataset from {excel_file}...")
    df = pd.read_excel(excel_file)
    df["thumbnail_url"] = df["thumbnail_url"].astype(object)

    updated_count = 0
    cleared_count = 0

    for idx, row in df.iterrows():
        name = row.get("name", "")
        if pd.isna(name) or not str(name).strip():
            continue

        name = str(name).strip()
        sanitized = sanitise_name(name)
        candidate = photo_root / f"{sanitized}.webp"

        if candidate.is_file():
            # Update to local path prefix served by backend
            relative_path = f"/assets/places/{candidate.name}"
            df.at[idx, "thumbnail_url"] = relative_path
            updated_count += 1
        else:
            # If the current value is a local assets path but file is missing, clear it
            current_url = row.get("thumbnail_url", "")
            if pd.notna(current_url) and str(current_url).startswith("/assets/"):
                df.at[idx, "thumbnail_url"] = None
                cleared_count += 1

    print(f"Saving updated dataset to {excel_file}...")
    df.to_excel(excel_file, index=False)

    print(f"Success: Synced local assets. Registered {updated_count} thumbnail(s), cleared {cleared_count} missing references.")

if __name__ == "__main__":
    main()
