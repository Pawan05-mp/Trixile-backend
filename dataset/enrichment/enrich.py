#!/usr/bin/env python3
"""
Pondicherry Places Enrichment Pipeline v3
=========================================
Author: Senior Data Engineer & Recommendation Systems Engineer
Description: A deterministic, production-ready enrichment pipeline for places data.
             Features safe LLM adjustments (restricted to max ±2 from baselines),
             high-fidelity deterministic fallbacks, strict validation layer,
             and pipeline threshold safety guards.
"""

import os
import sys
import json
import logging
import datetime
import re
import requests
import pandas as pd
import numpy as np

# Configure UTF-8 encoding for standard output/error
try:
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except Exception:
    pass

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Constants and Allowed Schema Sets
VALID_OCCASION_TAGS = {"date", "friends", "solo", "family", "work", "weekend", "celebration"}
VALID_ATMOSPHERE_TAGS = {
    "romantic", "quiet", "scenic", "outdoor", "indoor", "beachside", "luxury",
    "budget", "crowded", "family_friendly", "instagrammable", "conversation_friendly",
    "nature", "heritage", "late_night"
}

SCORE_FIELDS = [
    "date_score", "friends_score", "solo_score", "romantic_score",
    "conversation_score", "quiet_score", "scenic_score", "social_score",
    "activity_score", "comfort_score", "nature_score", "stimulation_score",
    "photo_score"
]

AREA_KEYWORDS = [
    "White Town", "Heritage Town", "Lawspet", "Auroville", "Muthialpet",
    "Mudaliarpet", "Nellithope", "Kathirkamam", "Oulgaret", "Marie Oulgaret",
    "Thavalakuppam", "Kottakuppam", "Ariyankuppam", "Mettupalayam",
    "Velrampet", "Murungapakkam", "Dubrayapet", "Duppuypet", "Colas Nagar",
    "Anna Nagar", "MG Road", "Mission Street", "Mission St", "Orleanpet",
    "Thiruvalluvar Nagar", "Kuilapalayam", "Edayanchavadi", "Karuvadikuppam",
    "Ellaipillaichavady"
]

# Prompt Templates
LLM_SYSTEM_PROMPT = """You are a scoring assistant for a Pondicherry places recommendation engine.
Given a place's details and its category baseline scores, return ONLY a JSON object with:
  "romantic_score" (integer 1-10)
  "photo_score" (integer 1-10)
  "occasion_tags" (array of strings, max 4, ONLY from: date, friends, solo, family, work, weekend, celebration)
  "atmosphere_tags" (array of strings, max 6, ONLY from: romantic, quiet, scenic, outdoor, indoor, beachside, luxury, budget, crowded, family_friendly, instagrammable, conversation_friendly, nature, heritage, late_night)

STRICT RULES:
1. Start from the provided baseline scores.
2. You may adjust romantic_score and photo_score by at most +/-2 from baseline.
3. Scores must be integers between 1 and 10.
4. Tags must only use the allowed values listed above.
5. Return ONLY raw JSON. No preamble, no markdown formatting (do not include ```json), no backticks.
"""

def load_baselines(path="category_baselines.json"):
    """Loads category baseline scores from JSON configuration."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            baselines = json.load(f)
        logger.info(f"Successfully loaded baselines for {len(baselines)} categories.")
        return baselines
    except Exception as e:
        logger.error(f"Failed to load baselines from {path}: {e}")
        sys.exit(1)

# --- DETERMINISTIC UTILITIES ---

def normalize_budget(budget):
    """
    Converts budget string representation into an integer rating from 1 to 6.
    Free -> 1
    Under ₹100 -> 2
    Under ₹200 -> 3
    Under ₹500 -> 4
    Under ₹1000 -> 5
    ₹1000+ -> 6
    """
    if pd.isna(budget) or not budget:
        return 1
    b_str = str(budget).strip().lower()
    if b_str in ["free", "n/a", "0", "free entry"]:
        return 1
    
    # Extract numeric digits
    digits = re.sub(r"[^0-9]", "", b_str)
    if not digits:
        return 1
    
    try:
        val = int(digits)
    except ValueError:
        return 1

    # Heuristics based on extracted bounds
    if val <= 100:
        return 2
    elif val <= 200:
        return 3
    elif val <= 500:
        return 4
    elif val <= 1000:
        return 5
    else:
        return 6

def extract_area(address):
    """
    Extracts neighborhood/area from free-text address.
    """
    if pd.isna(address) or not address:
        return "Puducherry"
    
    addr_str = str(address).strip()
    addr_lower = addr_str.lower()
    
    # Heuristic 1: Keyword-based mapping
    for kw in AREA_KEYWORDS:
        if kw.lower() in addr_lower:
            return kw
            
    # Heuristic 2: Strip pincode, grab last meaningful segment
    without_pin = re.sub(r"\b\d{6}\b", "", addr_str).strip()
    parts = [p.strip() for p in without_pin.split(",") if p.strip()]
    
    for part in reversed(parts):
        if (part and not re.match(r"^\d", part) and len(part) > 3 
                and "puducherry" not in part.lower() 
                and "pondicherry" not in part.lower() 
                and "tamil" not in part.lower()):
            return part
            
    return "Puducherry"

def to_minutes(time_val):
    """Converts a time string or object into minutes since midnight."""
    if pd.isna(time_val) or time_val is None:
        return None
        
    if isinstance(time_val, datetime.time):
        return time_val.hour * 60 + time_val.minute
    if isinstance(time_val, datetime.datetime):
        return time_val.hour * 60 + time_val.minute
        
    time_str = str(time_val).strip()
    if not time_str or time_str.lower() == "nan":
        return None
        
    try:
        # Match formats like HH:MM:SS, HH:MM
        parts = time_str.split(':')
        h = int(parts[0])
        m = int(parts[1]) if len(parts) > 1 else 0
        return h * 60 + m
    except Exception:
        return None

def get_best_visit_time(category, opening_time, closing_time):
    """
    Determines best visit time from category and opening hours.
    Possible values: morning, afternoon, sunset, evening, night, late_night
    """
    open_mins = to_minutes(opening_time)
    close_mins = to_minutes(closing_time)
    
    # Specific outdoor categories default to scenic times
    if category in ["walk", "beach", "park"]:
        return "sunset"
    if category == "peace":
        return "morning"
        
    if category == "fun":
        if close_mins is not None and (close_mins <= 4 * 60 or close_mins >= 22 * 60):
            return "late_night"
        return "evening"
        
    if open_mins is not None:
        if 4 * 60 <= open_mins < 10 * 60:
            return "morning"
        elif 10 * 60 <= open_mins < 14 * 60:
            return "afternoon"
        elif 14 * 60 <= open_mins < 18 * 60:
            return "evening"
        elif open_mins >= 18 * 60:
            return "night"
            
    if close_mins is not None and (close_mins <= 4 * 60 or close_mins == 0):
        return "late_night"
        
    return "evening"

def get_is_open_now(opening_time, closing_time):
    """Determines whether the place is currently open based on system time."""
    open_mins = to_minutes(opening_time)
    close_mins = to_minutes(closing_time)
    if open_mins is None or close_mins is None:
        return None
        
    now = datetime.datetime.now()
    now_mins = now.hour * 60 + now.minute
    
    if close_mins < open_mins:  # Overnight schedule (e.g. 17:00 to 02:00)
        return now_mins >= open_mins or now_mins <= close_mins
    if close_mins == 0:  # Midnight closing
        return now_mins >= open_mins
        
    return open_mins <= now_mins <= close_mins

# --- SCORING & ADJUSTMENT ENGINES ---

def clamp_score(value):
    """Clamps score to an integer between 1 and 10."""
    try:
        v = float(value)
        if pd.isna(v):
            return 5
        return max(1, min(10, int(round(v))))
    except Exception:
        return 5

def compute_deterministic_scores(place_data, baselines):
    """
    Computes deterministic scores based on baseline values, rating, reviews, budget, and address cues.
    All adjustments are capped and clamped strictly between 1 and 10.
    """
    category = place_data.get("Category", "quick_bite")
    # Fallback if category not found in baselines
    base = baselines.get(category, baselines.get("quick_bite"))
    
    rating = float(place_data.get("Rating", 4.0)) if not pd.isna(place_data.get("Rating")) else 4.0
    reviews = int(place_data.get("Reviews", 0)) if not pd.isna(place_data.get("Reviews")) else 0
    budget_level = normalize_budget(place_data.get("Budget"))
    
    # Heuristics & Signals
    rating_delta = (rating - 4.0) * 0.75  # Capped range roughly [-2.25, +0.75]
    pop_bonus = 1.0 if reviews >= 500 else 0.5 if reviews >= 100 else 0.0
    budget_comfort_bonus = 1.0 if budget_level >= 5 else -0.5 if budget_level <= 2 else 0.0
    
    address = str(place_data.get("Address", "")).lower()
    place_name = str(place_data.get("Name", "")).lower()
    
    is_beachside = any(kw in address or kw in place_name for kw in ["beach", "goubert", "rock beach", "seafront"])
    is_auroville = "auroville" in address or "auroville" in place_name
    is_whitetown = any(kw in address or kw in place_name for kw in ["white town", "french", "bussy"])
    is_heritage = "heritage" in address or "heritage" in place_name or "mission st" in address
    is_rooftop = "floor" in address and any(kw in address for kw in ["5th", "terrace", "top", "rooftop"])
    
    scenic_bonus = (2.0 if is_beachside else 0.0) + (1.0 if is_auroville else 0.0) + (1.0 if is_rooftop else 0.0)
    heritage_bonus = 1.0 if (is_whitetown or is_heritage) else 0.0
    nature_bonus = (2.0 if is_auroville else 0.0) + (2.0 if category == "walk" else 0.0)
    
    # Step 3: Emotion Engine Support & Baselines Adjustment
    # Custom rule for nature_score:
    is_nature_spot = any(kw in place_name or kw in address for kw in ["beach", "park", "lake", "garden", "botanical garden", "nature"])
    is_indoor_utility = any(kw in place_name or kw in address for kw in ["arcade", "gaming", "mall", "utility"]) or category == "quick_bite"
    
    nature_val = base.get("nature_score", 1)
    if is_nature_spot:
        nature_val = 10
    elif is_indoor_utility:
        nature_val = 1
    else:
        nature_val = clamp_score(nature_val + nature_bonus)
        
    # Custom rules for comfort_score:
    comfort_val = base.get("comfort_score", 5)
    is_cozy_relaxing = any(kw in place_name or kw in address for kw in ["cozy", "relaxing", "spa", "resort", "hotel", "cafe"])
    is_stressful_chaotic = "chaotic" in address or "stressful" in address or (reviews > 1000 and budget_level <= 2)
    
    if is_cozy_relaxing:
        comfort_val = 10
    elif is_stressful_chaotic:
        comfort_val = 1
    else:
        comfort_val = clamp_score(comfort_val + budget_comfort_bonus + rating_delta * 0.5)

    # Custom rules for stimulation_score:
    stimulation_val = base.get("stimulation_score", 5)
    is_gaming_arcade = any(kw in place_name or kw in address for kw in ["arcade", "gaming", "theme", "play", "zone", "fun"])
    is_quiet_park = category in ["peace", "walk"] or "quiet" in address or "ashram" in place_name
    
    if is_gaming_arcade:
        stimulation_val = 10
    elif is_quiet_park:
        stimulation_val = 1
    else:
        stimulation_val = clamp_score(stimulation_val + pop_bonus * 0.5)

    return {
        "date_score": clamp_score(base.get("date_score", 5) + rating_delta + heritage_bonus * 0.5),
        "friends_score": clamp_score(base.get("friends_score", 5) + rating_delta * 0.5 + pop_bonus),
        "solo_score": clamp_score(base.get("solo_score", 5) + rating_delta * 0.5),
        "conversation_score": clamp_score(base.get("conversation_score", 5) + rating_delta * 0.5),
        "quiet_score": clamp_score(base.get("quiet_score", 5) - pop_bonus * 0.5),
        "scenic_score": clamp_score(base.get("scenic_score", 5) + scenic_bonus + rating_delta * 0.5),
        "social_score": clamp_score(base.get("social_score", 5) + pop_bonus),
        "activity_score": clamp_score(base.get("activity_score", 5)),
        "comfort_score": comfort_val,
        "nature_score": nature_val,
        "stimulation_score": stimulation_val
    }

def get_deterministic_fallbacks(place_data, base_romantic, base_photo, det_scores):
    """
    Computes high-fidelity fallback values for romantic_score, photo_score,
    occasion_tags, and atmosphere_tags.
    """
    rating = float(place_data.get("Rating", 4.0)) if not pd.isna(place_data.get("Rating")) else 4.0
    rating_delta = (rating - 4.0) * 0.5
    
    address = str(place_data.get("Address", "")).lower()
    place_name = str(place_data.get("Name", "")).lower()
    category = place_data.get("Category", "quick_bite")
    budget_level = normalize_budget(place_data.get("Budget"))
    
    is_beachside = any(kw in address or kw in place_name for kw in ["beach", "goubert", "rock beach", "seafront"])
    is_whitetown = any(kw in address or kw in place_name for kw in ["white town", "french", "bussy"])
    is_heritage = "heritage" in address or "heritage" in place_name or "mission st" in address
    is_rooftop = "floor" in address and any(kw in address for kw in ["5th", "terrace", "top", "rooftop"])
    
    close_mins = to_minutes(place_data.get("Closing_Time"))
    is_late_night = close_mins is not None and (close_mins <= 4 * 60 or close_mins == 0)
    
    # Calculate deterministic fallback scores with +/- 2 limits
    rom_adjustment = rating_delta + (1.0 if (is_whitetown or is_beachside or "romantic" in place_name) else 0.0)
    rom_adj = clamp_score(base_romantic + rom_adjustment)
    romantic_score = max(base_romantic - 2, min(base_romantic + 2, rom_adj))
    
    pho_adjustment = rating_delta + (1.0 if (is_beachside or is_rooftop or "scenic" in address) else 0.0)
    pho_adj = clamp_score(base_photo + pho_adjustment)
    photo_score = max(base_photo - 2, min(base_photo + 2, pho_adj))
    
    # Calculate deterministic occasion tags
    occasions = []
    if romantic_score >= 7:
        occasions.append("date")
    if det_scores["friends_score"] >= 7:
        occasions.append("friends")
    if det_scores["solo_score"] >= 7:
        occasions.append("solo")
    if category in ["walk", "peace"]:
        occasions.append("family")
    if category == "fun":
        occasions.append("weekend")
    if det_scores["comfort_score"] >= 8 and det_scores["quiet_score"] >= 7:
        occasions.append("work")
    if det_scores["social_score"] >= 8 or category == "fun":
        occasions.append("celebration")
        
    occasion_tags = [t for t in occasions if t in VALID_OCCASION_TAGS][:4]
    
    # Calculate deterministic atmosphere tags
    atmos = []
    if romantic_score >= 7:
        atmos.append("romantic")
    if det_scores["quiet_score"] >= 7:
        atmos.append("quiet")
    if det_scores["scenic_score"] >= 7:
        atmos.append("scenic")
    if category == "walk":
        atmos.append("outdoor")
    if category in ["chill", "fun", "quick_bite"]:
        atmos.append("indoor")
    if is_beachside:
        atmos.append("beachside")
    if budget_level >= 5:
        atmos.append("luxury")
    if budget_level <= 2:
        atmos.append("budget")
    if det_scores["social_score"] >= 8:
        atmos.append("crowded")
    if category in ["walk", "park"]:
        atmos.append("family_friendly")
    if photo_score >= 8:
        atmos.append("instagrammable")
    if det_scores["conversation_score"] >= 8:
        atmos.append("conversation_friendly")
    if det_scores["nature_score"] >= 7:
        atmos.append("nature")
    if is_whitetown or is_heritage:
        atmos.append("heritage")
    if is_late_night:
        atmos.append("late_night")
        
    atmosphere_tags = [t for t in atmos if t in VALID_ATMOSPHERE_TAGS][:6]
    
    # Fallback values if list is empty
    if not occasion_tags:
        occasion_tags = ["solo"]
    if not atmosphere_tags:
        atmosphere_tags = ["indoor" if category == "quick_bite" else "quiet"]
        
    return romantic_score, photo_score, occasion_tags, atmosphere_tags

# --- LLM API INTEGRATION ---

def call_anthropic_api(api_key, prompt):
    """Calls Anthropic Messages API."""
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    payload = {
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 500,
        "system": LLM_SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": prompt}]
    }
    response = requests.post("https://api.anthropic.com/v1/messages", json=payload, headers=headers, timeout=12)
    response.raise_for_status()
    data = response.json()
    return data["content"][0]["text"]

def call_gemini_api(api_key, prompt):
    """Calls Gemini Content Generation API."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    payload = {
        "contents": [{"parts": [{"text": LLM_SYSTEM_PROMPT + "\n\n" + prompt}]}],
        "generationConfig": {
            "responseMimeType": "application/json"
        }
    }
    response = requests.post(url, json=payload, timeout=12)
    response.raise_for_status()
    data = response.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]

def query_llm_scores(place_data, base_romantic, base_photo, det_tags):
    """
    Attempts to call LLM APIs (Anthropic or Gemini) depending on available keys.
    Returns parsed scores and tags, or raises exception.
    """
    anthropic_key = os.environ.get("ANTHROPIC_API_KEY")
    gemini_key = os.environ.get("GEMINI_API_KEY")
    
    if not anthropic_key and not gemini_key:
        raise ValueError("No API keys configured.")
        
    prompt = f"""
Name: {place_data.get('Name')}
Category: {place_data.get('Category')}
Rating: {place_data.get('Rating')}
Reviews: {place_data.get('Reviews')}
Address: {place_data.get('Address')}
Budget: {place_data.get('Budget')}
Opening: {place_data.get('Opening_Time')} – Closing: {place_data.get('Closing_Time')}
Baseline romantic_score: {base_romantic}
Baseline photo_score: {base_photo}
Deterministic occasion_tags: {json.dumps(det_tags[0])}
Deterministic atmosphere_tags: {json.dumps(det_tags[1])}
"""
    
    if anthropic_key:
        response_text = call_anthropic_api(anthropic_key, prompt)
    else:
        response_text = call_gemini_api(gemini_key, prompt)
        
    # Extract JSON out of markdown blocks if any
    cleaned_text = response_text.strip()
    if cleaned_text.startswith("```"):
        cleaned_text = re.sub(r"^```(?:json)?\n|```$", "", cleaned_text, flags=re.MULTILINE).strip()
        
    parsed = json.loads(cleaned_text)
    return parsed

def run_scoring_engine(place_data, baselines, det_scores):
    """
    Orchestrates the scoring process. Determines starting baselines,
    checks for LLM API keys, runs the LLM query, clamps adjustments to +/-2 range,
    and falls back to deterministic computations on failure or key absence.
    """
    category = place_data.get("Category", "quick_bite")
    base = baselines.get(category, baselines.get("quick_bite"))
    
    # Starting baselines for LLM fields adjusted slightly by rating
    rating = float(place_data.get("Rating", 4.0)) if not pd.isna(place_data.get("Rating")) else 4.0
    rating_offset = int(round((rating - 4.0) * 0.5))
    
    base_romantic = clamp_score(base.get("romantic_score", 5) + rating_offset)
    base_photo = clamp_score(base.get("photo_score", 5) + rating_offset)
    
    # Calculate deterministic tags for LLM prompt context & fallback
    det_fallbacks = get_deterministic_fallbacks(place_data, base_romantic, base_photo, det_scores)
    det_tags = (det_fallbacks[2], det_fallbacks[3])
    
    # Attempt LLM Enrichment
    try:
        llm_data = query_llm_scores(place_data, base_romantic, base_photo, det_tags)
        
        # Enforce strict +/-2 baseline constraints on romantic & photo scores
        llm_romantic = int(llm_data.get("romantic_score", base_romantic))
        romantic_score = clamp_score(max(base_romantic - 2, min(base_romantic + 2, llm_romantic)))
        
        llm_photo = int(llm_data.get("photo_score", base_photo))
        photo_score = clamp_score(max(base_photo - 2, min(base_photo + 2, llm_photo)))
        
        # Filter output tags to only allowed subsets
        occasion_tags = [t for t in llm_data.get("occasion_tags", []) if t in VALID_OCCASION_TAGS][:4]
        atmosphere_tags = [t for t in llm_data.get("atmosphere_tags", []) if t in VALID_ATMOSPHERE_TAGS][:6]
        
        # Fall back if LLM returned empty arrays
        if not occasion_tags:
            occasion_tags = det_tags[0]
        if not atmosphere_tags:
            atmosphere_tags = det_tags[1]
            
        logger.debug(f"Successfully enriched {place_data.get('Name')} via LLM.")
        return romantic_score, photo_score, occasion_tags, atmosphere_tags, False
        
    except Exception as e:
        # Graceful fallback logic
        logger.debug(f"LLM enrichment failed for {place_data.get('Name')} ({e}). Using deterministic fallback.")
        romantic_score, photo_score, occasion_tags, atmosphere_tags = det_fallbacks
        return romantic_score, photo_score, occasion_tags, atmosphere_tags, True

# --- VALIDATION LAYER ---

# --- VALIDATION LAYER ---

def validate_scores_and_tags(enriched_record):
    """
    Validates the values of the final place record against the schema.
    Returns list of validation errors.
    """
    errors = []
    # 1. Verify scores in range 1-10
    for field in SCORE_FIELDS:
        val = enriched_record.get(field)
        if val is None or pd.isna(val):
            errors.append(f"{field}: missing")
        elif not isinstance(val, (int, np.integer)):
            errors.append(f"{field}: {val} is not an integer")
        elif val < 1 or val > 10:
            errors.append(f"{field}: {val} out of range [1, 10]")
    # 2. Rating (0-5)
    rating = enriched_record.get("rating")
    if rating is None:
        errors.append("rating: missing")
    elif not isinstance(rating, (int, float, np.floating)):
        errors.append(f"rating: {rating} not a number")
    elif rating < 0 or rating > 5:
        errors.append(f"rating: {rating} out of range [0, 5]")
    # 3. Reviews (integer >=0)
    reviews = enriched_record.get("reviews")
    if reviews is None:
        errors.append("reviews: missing")
    elif isinstance(reviews, float) and not reviews.is_integer():
        errors.append("reviews: contains decimal coordinates")
    elif not isinstance(reviews, (int, np.integer)):
        errors.append(f"reviews: {reviews} not an integer")
    elif reviews < 0:
        errors.append(f"reviews: {reviews} negative")
    # 4. Geo validation
    lat = enriched_record.get("lat")
    lng = enriched_record.get("lng")
    if lat is not None:
        if not isinstance(lat, (int, float, np.floating)) or lat < -90 or lat > 90:
            errors.append(f"lat: {lat} out of range [-90, 90]")
    if lng is not None:
        if not isinstance(lng, (int, float, np.floating)) or lng < -180 or lng > 180:
            errors.append(f"lng: {lng} out of range [-180, 180]")
    # 5. Address presence
    address = enriched_record.get("area")
    if not address:
        errors.append("area: empty address")
    # 6. Tags validation (unchanged)
    o_tags = enriched_record.get("occasion_tags", [])
    if not isinstance(o_tags, list):
        errors.append("occasion_tags: not a list")
    else:
        invalid_o = [t for t in o_tags if t not in VALID_OCCASION_TAGS]
        if invalid_o:
            errors.append(f"occasion_tags: invalid values {invalid_o}")
    a_tags = enriched_record.get("atmosphere_tags", [])
    if not isinstance(a_tags, list):
        errors.append("atmosphere_tags: not a list")
    else:
        invalid_a = [t for t in a_tags if t not in VALID_ATMOSPHERE_TAGS]
        if invalid_a:
            errors.append(f"atmosphere_tags: invalid values {invalid_a}")
    return errors
    """
    Validates the values of the final place record against the schema.
    Returns list of validation errors.
    """
    errors = []
    
    # 1. Verify scores in range 1-10
    for field in SCORE_FIELDS:
        val = enriched_record.get(field)
        if val is None or pd.isna(val):
            errors.append(f"{field}: missing")
        elif not isinstance(val, (int, np.integer)):
            errors.append(f"{field}: {val} is not an integer")
        elif val < 1 or val > 10:
            errors.append(f"{field}: {val} out of range [1, 10]")
            
    # 2. Verify occasion tags
    o_tags = enriched_record.get("occasion_tags", [])
    if not isinstance(o_tags, list):
        errors.append("occasion_tags: not a list")
    else:
        invalid_o = [t for t in o_tags if t not in VALID_OCCASION_TAGS]
        if invalid_o:
            errors.append(f"occasion_tags: invalid values {invalid_o}")
            
    # 3. Verify atmosphere tags
    a_tags = enriched_record.get("atmosphere_tags", [])
    if not isinstance(a_tags, list):
        errors.append("atmosphere_tags: not a list")
    else:
        invalid_a = [t for t in a_tags if t not in VALID_ATMOSPHERE_TAGS]
        if invalid_a:
            errors.append(f"atmosphere_tags: invalid values {invalid_a}")
            
    return errors

# --- PIPELINE MAIN ORCHESTRATOR ---

def main():
    logger.info("Initializing Enrichment Pipeline...")
    
    # 1. Load configuration baseline scores
    baselines = load_baselines("category_baselines.json")
    
    # 2. Load the source spreadsheet
    source_file = "Updated_Pondicherry_Data_with_Budget .xlsx"
    if not os.path.exists(source_file):
        logger.error(f"Source file {source_file} not found in workspace!")
        sys.exit(1)
        
    try:
        df_src = pd.read_excel(source_file)
        logger.info(f"Loaded {len(df_src)} records from {source_file}.")
    except Exception as e:
        logger.error(f"Failed to read source Excel file: {e}")
        sys.exit(1)
        
    enriched_records = []
    failed_enrichments = 0
    missing_fields_stats = {
        field: 0 for field in [
            "date_score", "friends_score", "solo_score", "romantic_score",
            "conversation_score", "quiet_score", "scenic_score", "social_score",
            "activity_score", "comfort_score", "nature_score", "stimulation_score",
            "photo_score", "is_open_now", "occasion_tags", "atmosphere_tags",
            "popularity_score", "quality_score", "recommendation_score"
        ]
    }
    
    # Verify source dataset mapping and process row-by-row
    for idx, row in df_src.iterrows():
        place_idx = idx + 1
        place_id = f"place_{place_idx:04d}"
        place_name = row.get("Name", "")
        category = row.get("Category", "quick_bite")
        
        # Safe extraction of basic properties
        address = row.get("Address", "")
        rating_raw = row.get("Rating")
        reviews_raw = row.get("Reviews")
        budget_raw = row.get("Budget")
        lat_raw = row.get("lat")
        lng_raw = row.get("lng")
        image_url_raw = row.get("image_url", "")
        opening_time_raw = row.get("Opening_Time")
        closing_time_raw = row.get("Closing_Time")
        google_maps_raw = row.get("Google_Maps", "")
        
        # Map parameters to clean types
        # Rating: float between 0 and 5 (validated later)
        rating = float(rating_raw) if not pd.isna(rating_raw) else None
        # Reviews: keep raw for normalization later
        if pd.isna(reviews_raw):
            reviews = None
        else:
            try:
                reviews = int(float(reviews_raw))
            except Exception:
                reviews = None
        # Latitude and Longitude
        lat = float(lat_raw) if not pd.isna(lat_raw) else None
        lng = float(lng_raw) if not pd.isna(lng_raw) else None
        lng = float(lng_raw) if not pd.isna(lng_raw) else None
        
        # Step 2: Deterministic logical fields (no AI)
        budget_level = normalize_budget(budget_raw)
        area = extract_area(address)
        best_visit_time = get_best_visit_time(category, opening_time_raw, closing_time_raw)
        is_open = get_is_open_now(opening_time_raw, closing_time_raw)
        
        # Step 3: Scoring computations
        det_scores = compute_deterministic_scores(row.to_dict(), baselines)
        
        # LLM scores (with deterministic fallback logic on key absence/error)
        rom_score, photo_score, o_tags, a_tags, was_fallback = run_scoring_engine(
            row.to_dict(), baselines, det_scores
        )
        
        reviews_val = reviews if reviews is not None else 0
        pop_bonus = 1.0 if reviews_val >= 500 else 0.5 if reviews_val >= 100 else 0.0
        popularity_score = clamp_score(5 + pop_bonus * 5)
        quality_score = clamp_score((rating or 4.0) * 2)
        recommendation_score = clamp_score((quality_score + popularity_score) / 2)
        category_confidence = 1.0
        
        # Assemble final record matching STEP 7 Final Schema
        record = {
            "id": place_id,
            "name": str(place_name).strip() if not pd.isna(place_name) else "",
            "category": str(category).strip() if not pd.isna(category) else "",
            "area": area,
            "rating": rating,
            "reviews": reviews,
            "budget_level": budget_level,
            "lat": lat,
            "lng": lng,
            "thumbnail_url": str(image_url_raw).strip() if not pd.isna(image_url_raw) else "",
            "detail_url": "",
            
            # Scores
            "date_score": det_scores["date_score"],
            "friends_score": det_scores["friends_score"],
            "solo_score": det_scores["solo_score"],
            "romantic_score": rom_score,
            "conversation_score": det_scores["conversation_score"],
            "quiet_score": det_scores["quiet_score"],
            "scenic_score": det_scores["scenic_score"],
            "social_score": det_scores["social_score"],
            "activity_score": det_scores["activity_score"],
            "comfort_score": det_scores["comfort_score"],
            "nature_score": det_scores["nature_score"],
            "stimulation_score": det_scores["stimulation_score"],
            "photo_score": photo_score,
            # New metrics
            "popularity_score": popularity_score,
            "quality_score": quality_score,
            "recommendation_score": recommendation_score,
            "category_confidence": category_confidence,
            
            # Tags (lists of strings)
            "occasion_tags": o_tags,
            "atmosphere_tags": a_tags,
            
            "best_visit_time": best_visit_time,
            "opening_time": str(opening_time_raw).strip() if not pd.isna(opening_time_raw) else "",
            "closing_time": str(closing_time_raw).strip() if not pd.isna(closing_time_raw) else "",
            "is_open_now": is_open,
            "google_maps_url": str(google_maps_raw).strip() if not pd.isna(google_maps_raw) else ""
        }
        
        # Validation
        val_errors = validate_scores_and_tags(record)
        record["validation_errors"] = "; ".join(val_errors) if val_errors else ""
        
        if val_errors:
            # Track failures and missing fields for auditing
            failed_enrichments += 1
            for err in val_errors:
                field = err.split(":")[0]
                if field in missing_fields_stats:
                    missing_fields_stats[field] += 1
        
        # Track individual missing field statistics for audit
        for field in missing_fields_stats:
            val = record.get(field)
            is_missing = False
            if val is None:
                is_missing = True
            elif isinstance(val, list):
                if not val:
                    is_missing = True
            else:
                try:
                    if pd.isna(val) or val == "":
                        is_missing = True
                except ValueError:
                    is_missing = True
            if is_missing:
                missing_fields_stats[field] += 1
                
        enriched_records.append(record)
        
    # Construct final dataframe
    df_enriched = pd.DataFrame(enriched_records)
    
    # 4. Count overall metrics
    total_records = len(df_src)
    successful_enrichments = total_records - failed_enrichments
    coverage = (successful_enrichments / total_records) * 100 if total_records > 0 else 0
    
    logger.info(f"Records loaded: {total_records}")
    logger.info(f"Records enriched: {successful_enrichments}")
    logger.info(f"Pipeline coverage: {coverage:.2f}%")
    
    # 5. Validation constraints (STEP 8 & Audit rules)
    # Check if >10% of rows have null/NaN date_score, romantic_score, or occasion_tags
    null_date_score_pct = (df_enriched["date_score"].isna().sum() / total_records) * 100
    # For lists, we check if they are empty
    null_occasion_tags_pct = (df_enriched["occasion_tags"].apply(lambda t: len(t) == 0).sum() / total_records) * 100
    null_romantic_score_pct = (df_enriched["romantic_score"].isna().sum() / total_records) * 100
    
    logger.info(f"Null date_score: {null_date_score_pct:.2f}%")
    logger.info(f"Empty occasion_tags: {null_occasion_tags_pct:.2f}%")
    logger.info(f"Null romantic_score: {null_romantic_score_pct:.2f}%")
    
    if null_date_score_pct > 10:
        raise ValueError(f"CRITICAL: >10% of rows have null date_score ({null_date_score_pct:.2f}%)")
    if null_occasion_tags_pct > 10:
        raise ValueError(f"CRITICAL: >10% of rows have empty/null occasion_tags ({null_occasion_tags_pct:.2f}%)")
    if null_romantic_score_pct > 10:
        raise ValueError(f"CRITICAL: >10% of rows have null romantic_score ({null_romantic_score_pct:.2f}%)")
        
    # Export audit report JSON
    audit_report = {
        "total_records": total_records,
        "enriched_records": successful_enrichments,
        "failed_records": failed_enrichments,
        "missing_fields": {k: v for k, v in missing_fields_stats.items() if v > 0}
    }
    
    with open("enrichment_report.json", "w", encoding="utf-8") as f_audit:
        json.dump(audit_report, f_audit, indent=2)
    logger.info("Exported audit report to enrichment_report.json.")
    
    # 6. Check if coverage is below 95%
    if coverage < 95.0:
        logger.error(f"Enrichment coverage of {coverage:.2f}% is below the 95% threshold. Aborting Excel export.")
        sys.exit(1)
        
    # Convert lists to comma-separated strings for final Excel export sheet representation
    df_export = df_enriched.copy()
    df_export["occasion_tags"] = df_export["occasion_tags"].apply(lambda x: ", ".join(x))
    df_export["atmosphere_tags"] = df_export["atmosphere_tags"].apply(lambda x: ", ".join(x))
    
    # Ensure correct final column order
    final_cols = [
        "id", "name", "category", "area", "rating", "reviews", "budget_level",
        "lat", "lng", "thumbnail_url", "detail_url",
        "date_score", "friends_score", "solo_score", "romantic_score",
        "conversation_score", "quiet_score", "scenic_score", "social_score",
        "activity_score", "comfort_score", "nature_score", "stimulation_score",
        "photo_score", "popularity_score", "quality_score", "recommendation_score",
        "occasion_tags", "atmosphere_tags", "best_visit_time",
        "opening_time", "closing_time", "is_open_now", "google_maps_url"
    ]
    df_export = df_export[final_cols]
    
    # 7. Print head of final export dataset
    logger.info("First 5 rows of enriched place dataset:")
    print(df_export.head())
    
    # 8. Export to excel file
    output_file = "Pondicherry_Enriched_v3.xlsx"
    try:
        df_export.to_excel(output_file, index=False)
        logger.info(f"Successfully exported final enriched data to {output_file} ({len(df_export)} records).")
    except Exception as e:
        logger.error(f"Failed to export to {output_file}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
