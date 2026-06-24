from pathlib import Path
import re
import shutil

# Your source folder
SOURCE_DIR = Path(r"C:\Users\pawan\Downloads\BulkResizePhotos.com")

# New folder for renamed images
OUTPUT_DIR = SOURCE_DIR / "renamed"
OUTPUT_DIR.mkdir(exist_ok=True)

for file in SOURCE_DIR.glob("*.webp"):
    # Get filename without extension
    name = file.stem

    # Convert to URL-safe slug
    name = name.lower()
    name = name.replace("'", "")
    name = re.sub(r"[^a-z0-9]+", "-", name)
    name = re.sub(r"-+", "-", name)
    name = name.strip("-")

    new_filename = f"{name}.webp"
    new_path = OUTPUT_DIR / new_filename

    # Copy original file to new folder with new name
    shutil.copy2(file, new_path)

    print(f"{file.name}  -->  {new_filename}")

print("\nDone!")
print(f"Renamed files saved to:\n{OUTPUT_DIR}")