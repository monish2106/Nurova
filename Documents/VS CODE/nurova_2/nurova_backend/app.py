"""
Nurova 2.0 — Flask Backend API
Endpoints:
  POST /predict_distraction
  POST /get_personality
  GET  /recommend_content
  POST /log_session
  GET  /health
  GET  /metrics

Run locally:  python app.py
Deploy:       gunicorn app:app --bind 0.0.0.0:$PORT
"""

import os
import json
import sqlite3
import joblib
import numpy as np
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

DB_PATH = "nurova.db"
MODELS_DIR = "models"
YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY", "YOUR_YOUTUBE_API_KEY_HERE")

# ─────────────────────────────────────────────
# Load Models (lazy load at startup)
# ─────────────────────────────────────────────

_distraction_model = None
_cluster_model = None

def get_distraction_model():
    global _distraction_model
    if _distraction_model is None:
        path = os.path.join(MODELS_DIR, "distraction_model.pkl")
        if os.path.exists(path):
            _distraction_model = joblib.load(path)
        else:
            raise FileNotFoundError("distraction_model.pkl not found. Run train_models.py first.")
    return _distraction_model

def get_cluster_model():
    global _cluster_model
    if _cluster_model is None:
        path = os.path.join(MODELS_DIR, "cluster_model.pkl")
        if os.path.exists(path):
            _cluster_model = joblib.load(path)
        else:
            raise FileNotFoundError("cluster_model.pkl not found. Run train_models.py first.")
    return _cluster_model


# ─────────────────────────────────────────────
# Database Setup
# ─────────────────────────────────────────────

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            screen_time REAL,
            productive_mins INTEGER,
            apps_used TEXT,
            risk_prob REAL,
            personality_cluster TEXT,
            created_at TEXT
        )
    """)
    conn.commit()
    conn.close()


init_db()


# ─────────────────────────────────────────────
# Content Scoring Algorithm
# ─────────────────────────────────────────────

CONTENT_CATALOG = [
    {"title": "5 LeetCode Patterns You MUST Know", "url": "https://youtu.be/0K_eZGS5NsU",
     "thumbnail": "https://img.youtube.com/vi/0K_eZGS5NsU/hqdefault.jpg",
     "channel": "NeetCode", "duration": "11 min", "category": "DSA",
     "views": 450000, "duration_mins": 11, "goal_relevance": 0.95, "user_interest": 0.88},
    {"title": "System Design Interview — Step by Step Guide", "url": "https://youtu.be/bUHFg8CZFws",
     "thumbnail": "https://img.youtube.com/vi/bUHFg8CZFws/hqdefault.jpg",
     "channel": "Gaurav Sen", "duration": "14 min", "category": "System Design",
     "views": 1200000, "duration_mins": 14, "goal_relevance": 0.92, "user_interest": 0.85},
    {"title": "Python DSA Crash Course", "url": "https://youtu.be/pkYVOmU3MgA",
     "thumbnail": "https://img.youtube.com/vi/pkYVOmU3MgA/hqdefault.jpg",
     "channel": "Tech With Tim", "duration": "10 min", "category": "DSA",
     "views": 320000, "duration_mins": 10, "goal_relevance": 0.90, "user_interest": 0.82},
    {"title": "ML Pipeline End-to-End in 15 min", "url": "https://youtu.be/7eh4d6sabA0",
     "thumbnail": "https://img.youtube.com/vi/7eh4d6sabA0/hqdefault.jpg",
     "channel": "Sentdex", "duration": "13 min", "category": "ML/AI",
     "views": 280000, "duration_mins": 13, "goal_relevance": 0.87, "user_interest": 0.80},
    {"title": "How to Deep Work — Cal Newport Method", "url": "https://youtu.be/ZD7dXfdDPfg",
     "thumbnail": "https://img.youtube.com/vi/ZD7dXfdDPfg/hqdefault.jpg",
     "channel": "Thomas Frank", "duration": "9 min", "category": "Productivity",
     "views": 850000, "duration_mins": 9, "goal_relevance": 0.78, "user_interest": 0.75},
    {"title": "Focus Music — Deep Work Session 🎵", "url": "https://youtu.be/jfKfPfyJRdk",
     "thumbnail": "https://img.youtube.com/vi/jfKfPfyJRdk/hqdefault.jpg",
     "channel": "Lofi Girl", "duration": "57 min", "category": "Mindfulness",
     "views": 5000000, "duration_mins": 57, "goal_relevance": 0.60, "user_interest": 0.90},
    {"title": "Pomodoro Technique — Explained Properly", "url": "https://youtu.be/VFW3Ld7JO0w",
     "thumbnail": "https://img.youtube.com/vi/VFW3Ld7JO0w/hqdefault.jpg",
     "channel": "Thomas Frank", "duration": "7 min", "category": "Productivity",
     "views": 1100000, "duration_mins": 7, "goal_relevance": 0.75, "user_interest": 0.72},
    {"title": "REST API Design — Best Practices", "url": "https://youtu.be/7nm1pYuKAhY",
     "thumbnail": "https://img.youtube.com/vi/7nm1pYuKAhY/hqdefault.jpg",
     "channel": "Fireship", "duration": "11 min", "category": "Web Dev",
     "views": 680000, "duration_mins": 11, "goal_relevance": 0.88, "user_interest": 0.85},
]

CLUSTER_BOOSTS = {
    "NightScrollAddict": {"Mindfulness": 0.15, "Productivity": 0.10},
    "StressScroller": {"Mindfulness": 0.20, "Productivity": 0.10},
    "ProcrastinationBinger": {"DSA": 0.10, "System Design": 0.10, "Productivity": 0.05},
    "ProductiveSprinter": {"ML/AI": 0.10, "System Design": 0.10},
}

RISK_FILTERS = {
    "high": lambda x: x["duration_mins"] <= 15,
    "medium": lambda x: x["duration_mins"] <= 30,
    "low": lambda x: True,
}


def score_content(item, risk_level, cluster, query=""):
    mood_match = 0.5
    if risk_level == "high" and item["category"] in ("Mindfulness", "Productivity"):
        mood_match = 0.9
    elif risk_level == "low" and item["category"] in ("DSA", "System Design", "ML/AI"):
        mood_match = 0.85

    goal_relevance = item["goal_relevance"]
    user_interest = item["user_interest"]

    # Query match boost
    if query and query.lower() in item["title"].lower():
        goal_relevance = min(goal_relevance + 0.08, 1.0)
    if query and query.lower() in item["category"].lower():
        goal_relevance = min(goal_relevance + 0.05, 1.0)

    # Cluster boost
    boosts = CLUSTER_BOOSTS.get(cluster, {})
    cluster_boost = boosts.get(item["category"], 0)

    score = (goal_relevance * 0.6) + (user_interest * 0.3) + (mood_match * 0.1) + cluster_boost
    return round(min(score, 1.0), 3)


# ─────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "version": "2.0.0", "timestamp": datetime.utcnow().isoformat()})


@app.route("/metrics", methods=["GET"])
def metrics():
    result = {}
    for fname in ("distraction_metrics.json", "cluster_metrics.json"):
        path = os.path.join(MODELS_DIR, fname)
        if os.path.exists(path):
            with open(path) as f:
                result[fname.replace("_metrics.json", "")] = json.load(f)
    return jsonify(result)


@app.route("/predict_distraction", methods=["POST"])
def predict_distraction():
    data = request.get_json(force=True)

    required = [
        "screen_time", "distraction_freq", "mood_score",
        "goal_alignment_score", "task_completion_rate",
        "time_of_day", "hour_of_session",
    ]

    try:
        pkg = get_distraction_model()
        model = pkg["model"]
        scaler = pkg["scaler"]
        features = pkg["features"]

        # Map request fields → model features
        feature_map = {
            "daily_screen_time": float(data.get("screen_time", 4)),
            "distraction_frequency": float(data.get("distraction_freq", 10)),
            "mood_score": float(data.get("mood_score", 5)),
            "goal_alignment_score": float(data.get("goal_alignment_score", 0.5)),
            "task_completion_rate": float(data.get("task_completion_rate", 0.5)),
            "time_of_day": float(data.get("time_of_day", 12)),
            "hour_of_session": float(data.get("hour_of_session", 1)),
        }

        X = np.array([[feature_map[f] for f in features]])
        X_scaled = scaler.transform(X)
        risk_prob = float(model.predict_proba(X_scaled)[0][1])

    except Exception as e:
        # Fallback heuristic
        screen_time = float(data.get("screen_time", 4))
        mood = float(data.get("mood_score", 5))
        hour = float(data.get("time_of_day", 12))
        risk_prob = min(
            0.3 + (screen_time / 16) * 0.35
              + (1 - mood / 10) * 0.2
              + (0.15 if hour >= 22 or hour <= 4 else 0),
            0.99
        )

    if risk_prob > 0.75:
        action = "HIGH_RISK"
    elif risk_prob > 0.45:
        action = "MEDIUM_RISK"
    else:
        action = "LOW_RISK"

    return jsonify({
        "risk_prob": round(risk_prob, 4),
        "action": action,
        "risk_percent": round(risk_prob * 100, 1),
        "timestamp": datetime.utcnow().isoformat(),
    })


@app.route("/get_personality", methods=["POST"])
def get_personality():
    data = request.get_json(force=True)
    history = data.get("usage_history", [{}])

    try:
        pkg = get_cluster_model()
        model = pkg["model"]
        scaler = pkg["scaler"]
        features = pkg["features"]
        name_map = pkg["cluster_name_map"]
        traits_map = pkg["cluster_traits"]

        # Aggregate history → single feature vector
        avg = {}
        for feat in features:
            vals = [float(row.get(feat, 0)) for row in history if feat in row or True]
            avg[feat] = np.mean(vals) if vals else 0.0

        # Map request fields
        feature_map = {
            "daily_screen_time": float(history[0].get("screen_time", avg.get("daily_screen_time", 4))),
            "distraction_frequency": float(history[0].get("distraction_freq", avg.get("distraction_frequency", 10))),
            "mood_score": float(history[0].get("mood_score", avg.get("mood_score", 5))),
            "goal_alignment_score": float(history[0].get("goal_alignment_score", avg.get("goal_alignment_score", 0.5))),
            "task_completion_rate": float(history[0].get("task_completion_rate", avg.get("task_completion_rate", 0.5))),
            "time_of_day": float(history[0].get("time_of_day", avg.get("time_of_day", 12))),
        }

        X = np.array([[feature_map[f] for f in features]])
        X_scaled = scaler.transform(X)
        cluster_id = int(model.predict(X_scaled)[0])
        cluster_name = name_map.get(cluster_id, "ProcrastinationBinger")

    except Exception:
        cluster_name = "ProcrastinationBinger"

    emoji_map = {
        "NightScrollAddict": "🌙",
        "StressScroller": "😰",
        "ProcrastinationBinger": "📱",
        "ProductiveSprinter": "⚡",
    }
    traits_map_full = {
        "NightScrollAddict": ["Active late-night (10 PM+)", "Long scroll sessions", "Low next-day productivity"],
        "StressScroller": ["High distraction frequency", "Low mood score", "Frequent context-switching"],
        "ProcrastinationBinger": ["High screen time", "Low task completion", "Short productivity bursts"],
        "ProductiveSprinter": ["Strong goal alignment", "Low distraction", "Consistent task completion"],
    }

    return jsonify({
        "cluster": cluster_name,
        "traits": traits_map_full.get(cluster_name, []),
        "emoji": emoji_map.get(cluster_name, "🤖"),
        "display_name": cluster_name.replace("_", " "),
    })


@app.route("/recommend_content", methods=["GET"])
def recommend_content():
    query = request.args.get("query", "DSA")
    risk_level = request.args.get("risk_level", "medium")
    cluster = request.args.get("cluster", "ProcrastinationBinger")

    # Try YouTube API first, fallback to catalog
    items = None
    if YOUTUBE_API_KEY and YOUTUBE_API_KEY != "YOUR_YOUTUBE_API_KEY_HERE":
        items = _fetch_youtube(query, risk_level)

    if not items:
        items = CONTENT_CATALOG

    risk_filter = RISK_FILTERS.get(risk_level, RISK_FILTERS["medium"])

    scored = []
    for item in items:
        if not risk_filter(item):
            continue
        if item.get("views", 1001) < 1000:
            continue
        s = score_content(item, risk_level, cluster, query)
        if s >= 0.65:
            scored.append({**item, "score": s})

    scored.sort(key=lambda x: x["score"], reverse=True)
    return jsonify(scored[:8])


def _fetch_youtube(query, risk_level):
    """Fetch from YouTube Data API v3"""
    try:
        from googleapiclient.discovery import build
        duration_map = {"high": "short", "medium": "medium", "low": "any"}
        yt = build("youtube", "v3", developerKey=YOUTUBE_API_KEY)
        search_resp = yt.search().list(
            q=query + " tutorial",
            type="video",
            part="snippet",
            maxResults=10,
            videoDuration=duration_map.get(risk_level, "medium"),
            relevanceLanguage="en",
        ).execute()

        items = []
        for item in search_resp.get("items", []):
            vid_id = item["id"]["videoId"]
            snippet = item["snippet"]
            items.append({
                "title": snippet["title"],
                "url": f"https://youtu.be/{vid_id}",
                "thumbnail": snippet["thumbnails"]["high"]["url"],
                "channel": snippet["channelTitle"],
                "duration": "~10 min",
                "category": query,
                "views": 5000,
                "duration_mins": 10,
                "goal_relevance": 0.82,
                "user_interest": 0.78,
            })
        return items
    except Exception:
        return None


@app.route("/log_session", methods=["POST"])
def log_session():
    data = request.get_json(force=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        INSERT INTO sessions (screen_time, productive_mins, apps_used, risk_prob, personality_cluster, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        float(data.get("screen_time", 0)),
        int(data.get("productive_mins", 0)),
        json.dumps(data.get("apps_used", [])),
        float(data.get("risk_prob", 0)),
        data.get("personality_cluster", ""),
        datetime.utcnow().isoformat(),
    ))
    conn.commit()
    conn.close()
    return jsonify({"status": "logged", "id": c.lastrowid})


@app.route("/analytics", methods=["GET"])
def analytics():
    """Return 7-day aggregated analytics"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    seven_days_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()
    rows = c.execute("""
        SELECT DATE(created_at) as date, 
               AVG(risk_prob) as avg_risk,
               SUM(screen_time) as total_screen_time,
               COUNT(*) as sessions
        FROM sessions
        WHERE created_at >= ?
        GROUP BY DATE(created_at)
        ORDER BY date
    """, (seven_days_ago,)).fetchall()
    conn.close()

    result = [
        {"date": r[0], "avg_risk": round(r[1], 3),
         "total_screen_time": round(r[2], 2), "sessions": r[3]}
        for r in rows
    ]
    return jsonify(result)


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("FLASK_DEBUG", "true").lower() == "true"
    print(f"🚀 Nurova API starting on port {port}")
    app.run(host="0.0.0.0", port=port, debug=debug)
