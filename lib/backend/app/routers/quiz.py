from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.db_models import QuizHistory
from app.data import QUESTIONS
from app.models import AnswerSubmit

router = APIRouter()

@router.get("/questions")
def get_questions():
    return [q.model_dump(exclude={"correct_option_id", "is_phishing"}) for q in QUESTIONS]

@router.post("/answer")
def check_answer(body: AnswerSubmit, db: Session = Depends(get_db)):
    question = next((q for q in QUESTIONS if q.id == body.question_id), None)
    if not question:
        return {"error": "Question not found"}
    correct = body.selected_option_id == question.correct_option_id
    points  = question.points if correct else 0
    user_id = getattr(body, "user_id", 1)

    # Save to history
    db.add(QuizHistory(
        user_id     = user_id,
        question_id = body.question_id,
        category    = question.category,
        is_correct  = correct,
        points      = points,
        scenario    = question.scenario[:120] + "..." if len(question.scenario) > 120 else question.scenario,
    ))
    db.commit()

    return {
        "correct": correct,
        "correct_option_id": question.correct_option_id,
        "explanation": question.explanation,
        "is_phishing": question.is_phishing,
        "points": points,
    }

@router.get("/questions/{question_id}")
def get_question(question_id: str):
    question = next((q for q in QUESTIONS if q.id == question_id), None)
    if not question:
        return {"error": "Not found"}
    return question.model_dump(exclude={"correct_option_id", "is_phishing"})
