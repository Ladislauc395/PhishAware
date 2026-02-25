from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.db_models import UserStats, QuizHistory, User
from datetime import datetime, timezone

router = APIRouter()

LEVELS = [
    (0,     "Iniciante"),
    (500,   "Aprendiz"),
    (1500,  "Defensor"),
    (3000,  "Especialista"),
    (6000,  "Mestre"),
    (10000, "Sentinela Elite"),
]

def _compute_level(xp: int) -> str:
    level = "Iniciante"
    for threshold, name in LEVELS:
        if xp >= threshold:
            level = name
    return level

def _get_or_create_stats(db: Session, user_id: int) -> UserStats:
    stats = db.query(UserStats).filter(UserStats.user_id == user_id).first()
    if not stats:
        stats = UserStats(
            user_id=user_id,
            by_category={"email": 0, "sms": 0, "url": 0, "app": 0},
            show_in_ranking=True,
        )
        db.add(stats)
        db.commit()
        db.refresh(stats)
    return stats

@router.get("/")
def get_stats(user_id: int = Query(default=1), db: Session = Depends(get_db)):
    stats = _get_or_create_stats(db, user_id)
    return {
        "xp": stats.xp,
        "resilience": stats.resilience,
        "level": stats.level,
        "correct_total": stats.correct_total,
        "answered_total": stats.answered_total,
        "by_category": stats.by_category or {"email": 0, "sms": 0, "url": 0, "app": 0},
        "show_in_ranking": stats.show_in_ranking if stats.show_in_ranking is not None else True,
    }

@router.post("/add-xp")
def add_xp(payload: dict, db: Session = Depends(get_db)):
    user_id  = payload.get("user_id", 1)
    xp       = payload.get("xp", 0)
    correct  = payload.get("correct", False)
    category = payload.get("category", "email")
    scenario = payload.get("scenario", "")

    stats = _get_or_create_stats(db, user_id)
    stats.xp += xp
    stats.answered_total += 1
    if correct:
        stats.correct_total += 1
        by_cat = dict(stats.by_category or {})
        by_cat[category] = by_cat.get(category, 0) + 1
        stats.by_category = by_cat

    total = stats.answered_total
    stats.resilience = int((stats.correct_total / total) * 100) if total else 0
    stats.level = _compute_level(stats.xp)

    history_entry = QuizHistory(
        user_id=user_id,
        question_id=payload.get("question_id", "sim"),
        category=category,
        is_correct=correct,
        points=xp,
        scenario=scenario if scenario else "Simulação",
        # ✅ CORRIGIDO: timezone-aware UTC em vez de utcnow() deprecated
        timestamp=datetime.now(timezone.utc),
    )
    db.add(history_entry)
    db.commit()
    db.refresh(stats)

    return {
        "xp": stats.xp,
        "resilience": stats.resilience,
        "level": stats.level,
        "correct_total": stats.correct_total,
        "answered_total": stats.answered_total,
        "by_category": stats.by_category,
    }

@router.post("/preferences")
def update_preferences(payload: dict, db: Session = Depends(get_db)):
    user_id         = payload.get("user_id", 1)
    show_in_ranking = payload.get("show_in_ranking")

    stats = _get_or_create_stats(db, user_id)

    if show_in_ranking is not None:
        stats.show_in_ranking = bool(show_in_ranking)

    db.commit()
    db.refresh(stats)

    return {"show_in_ranking": stats.show_in_ranking}

@router.get("/history")
def get_history(user_id: int = Query(default=1), limit: int = 30,
                db: Session = Depends(get_db)):
    rows = (db.query(QuizHistory)
              .filter(QuizHistory.user_id == user_id)
              .order_by(QuizHistory.timestamp.desc())
              .limit(limit).all())
    return [
        {
            "id": r.id,
            "question_id": r.question_id,
            "category": r.category,
            "is_correct": r.is_correct,
            "points": r.points,
            "scenario": r.scenario,
            "timestamp": r.timestamp.strftime("%Y-%m-%dT%H:%M:%SZ") if r.timestamp else None,
        }
        for r in rows
    ]

@router.get("/ranking")
def get_ranking(db: Session = Depends(get_db)):
    rows = (db.query(UserStats, User)
              .join(User, UserStats.user_id == User.id)
              .filter(UserStats.show_in_ranking == True)
              .order_by(UserStats.xp.desc())
              .limit(20).all())
    return [
        {
            "user_id": u.id,
            "name": u.name,
            "avatar_letter": u.avatar_letter,
            "xp": s.xp,
            "level": s.level,
            "correct_total": s.correct_total,
        }
        for s, u in rows
    ]