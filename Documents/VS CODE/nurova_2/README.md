# 🧠 Nurova 2.0 — AI-Powered Distraction Detection & Productivity Companion

> A 7-day hackathon MVP with real ML, real APIs, and real impact.

![Nurova Banner](https://via.placeholder.com/900x300/0D0D1A/6C63FF?text=Nurova+2.0+%E2%80%94+Stop+Scrolling.+Start+Building.)

---

## 🎯 What Is Nurova?

Nurova 2.0 is an AI-powered mobile app that:
- **Detects** when you're at risk of distraction in real time
- **Clusters** you into one of 4 personality types based on usage patterns
- **Recommends** focused, goal-relevant YouTube content
- **Nudges** you back to productivity with sentiment-aware messages

---

## 📊 ML Performance Metrics

| Model | Metric | Score | Target |
|-------|--------|-------|--------|
| Distraction Predictor | Accuracy | **86.5%** | ≥ 85% ✅ |
| Distraction Predictor | Precision | **87%** | — |
| Distraction Predictor | Recall | **84%** | — |
| Personality Clustering | Silhouette | 0.12 | ≥ 0.60 |
| Productivity Lift | A/B sim | **+28%** | ≥ 25% ✅ |
| API Response Time | P95 | **< 200ms** | < 500ms ✅ |

### Confusion Matrix (400 test samples)
```
           Predicted No Risk  Predicted At Risk
Actual No Risk     186 (TN)         23 (FP)
Actual At Risk      31 (FN)        160 (TP)
```

### 4 Personality Clusters
| Type | Traits | Intervention |
|------|--------|--------------|
| 🌙 Night Scroll Addict | Active 10PM+, long sessions | Screen cutoff + focus music |
| 😰 Stress Scroller | High distraction freq, low mood | Breathing exercises + short content |
| 📱 Procrastination Binger | High screen time, low task completion | Pomodoro + micro-goals |
| ⚡ Productive Sprinter | Strong goal alignment | Advanced content, stretch goals |

---

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│        Flutter Mobile App        │
│  HomeScreen  DashboardScreen    │
│  RecommendationsScreen Settings │
│  BLoC State Management          │
└──────────────┬──────────────────┘
               │ HTTP (REST)
┌──────────────▼──────────────────┐
│         Flask Python API         │
│  /predict_distraction            │
│  /get_personality                │
│  /recommend_content              │
│  /log_session                    │
└──────────────┬──────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
  ┌─────────┐   ┌─────────────┐
  │ ML Models│   │ YouTube API │
  │ (joblib) │   │   v3        │
  │ LogReg+  │   └─────────────┘
  │ RF+KMeans│
  └─────────┘
       │
  ┌────▼────┐
  │  SQLite  │
  │ Sessions │
  └─────────┘
```

---

## 🚀 Quick Start

### Backend (Flask + ML)
```bash
cd nurova_backend
chmod +x setup.sh && ./setup.sh
# OR manually:
pip install -r requirements.txt
python train_models.py   # Trains + pickles models (~30s)
python app.py            # Starts API on :5000
```

### Frontend (Flutter)
```bash
cd nurova_flutter
flutter pub get
flutter run              # iOS / Android / Web
```

Point the app to your backend in Settings → API URL.

---

## 📡 API Reference

### `POST /predict_distraction`
```json
// Request
{
  "screen_time": 8.5,
  "distraction_freq": 22,
  "mood_score": 4,
  "goal_alignment_score": 0.35,
  "task_completion_rate": 0.40,
  "time_of_day": 23,
  "hour_of_session": 2
}

// Response
{
  "risk_prob": 0.87,
  "action": "HIGH_RISK",
  "risk_percent": 87.0,
  "timestamp": "2024-01-15T23:45:00"
}
```

### `POST /get_personality`
```json
// Request
{ "usage_history": [{ "screen_time": 10, "mood_score": 3, ... }] }

// Response
{
  "cluster": "NightScrollAddict",
  "traits": ["Active late-night (10 PM+)", "Long scroll sessions", "Low next-day productivity"],
  "emoji": "🌙"
}
```

### `GET /recommend_content?query=DSA&risk_level=high&cluster=ProcrastinationBinger`
```json
[
  {
    "title": "5 LeetCode Patterns You MUST Know",
    "url": "https://youtu.be/...",
    "score": 0.94,
    "channel": "NeetCode",
    "duration": "11 min"
  }
]
```

---

## 🧮 Content Scoring Algorithm

```python
content_score = (goal_relevance * 0.6) + (user_interest * 0.3) + (mood_match * 0.1)

# Filters applied:
# score > 0.70  AND  duration < 15 min (high risk)  AND  views > 1,000
```

---

## 🌐 Deploy to Render (1-click)

1. Push `nurova_backend/` to GitHub
2. Go to [render.com](https://render.com) → New Web Service
3. Connect repo → Render detects `render.yaml` automatically
4. Add `YOUTUBE_API_KEY` in Environment Variables
5. Deploy → copy URL → paste into app Settings

---

## 📁 Project Structure

```
nurova_2/
├── nurova_flutter/           # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart         # App entry + theme
│   │   ├── bloc/             # State management
│   │   │   ├── session_bloc.dart
│   │   │   └── prediction_bloc.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── recommendations_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── widgets/
│   │   │   ├── glass_card.dart
│   │   │   ├── personality_badge.dart
│   │   │   └── nudge_banner.dart
│   │   ├── models/
│   │   │   ├── session_model.dart
│   │   │   └── prediction_model.dart
│   │   └── services/
│   │       ├── api_service.dart
│   │       ├── database_service.dart
│   │       └── notification_service.dart
│   └── pubspec.yaml
│
├── nurova_backend/           # Flask Python API
│   ├── app.py                # Main API (all endpoints)
│   ├── train_models.py       # ML training pipeline
│   ├── requirements.txt
│   ├── Procfile              # Gunicorn config
│   ├── render.yaml           # Render deployment
│   └── .env.example
│
├── models/                   # Pre-trained pickled models
│   ├── distraction_model.pkl
│   ├── cluster_model.pkl
│   ├── distraction_metrics.json
│   └── cluster_metrics.json
│
├── dataset/
│   └── synthetic_data.csv    # 2000-row training data
│
└── README.md
```

---

## 🎬 Demo Flow (Hackathon Walkthrough)

1. **Open app** → Shows live session timer: `2h 47m`
2. **Tap "Analyze Now"** → Risk meter spikes to `87%` → "HIGH RISK" badge
3. **Nudge fires** → "Night Scroll detected! One LeetCode = dopamine hit 🧠"
4. **Personality tab** → "Procrastination Binger 📱" — traits listed
5. **Learn tab** → "5min Python DSA videos" curated for your type + risk
6. **Dashboard** → Line chart shows `+28% productivity vs yesterday`
7. **Settings** → Set API URL, log mood, adjust screen time limit

---

## 🛠️ 7-Day Build Plan

| Day | Focus | Status |
|-----|-------|--------|
| 1 | Flutter skeleton + session timer | ✅ Done |
| 2 | Flask backend + synthetic dataset | ✅ Done |
| 3 | Train ML models, pickle, test API | ✅ Done |
| 4 | Distraction prediction integration | ✅ Done |
| 5 | Clustering + personality UI | ✅ Done |
| 6 | YouTube recommendations + polish | ✅ Done |
| 7 | Metrics dashboard + demo video | 🎬 Record & ship |

---

## 🔑 Get YouTube API Key

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. New Project → Enable **YouTube Data API v3**
3. Credentials → Create API Key
4. Add to `.env`: `YOUTUBE_API_KEY=your_key`

Without a key, the app uses its curated fallback content catalog.

---

## 📄 License

MIT — build on it, hack it, ship it.

---

*Built with ❤️ for the 7-Day Hackathon. Made to make judges say "this is a real AI product."*
