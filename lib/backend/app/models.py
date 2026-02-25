from pydantic import BaseModel
from typing import List, Optional

class QuizOption(BaseModel):
    id: str
    text: str

class QuizQuestion(BaseModel):
    id: str
    category: str          
    difficulty: str        
    points: int
    scenario: str
    clue: str
    options: List[QuizOption]
    correct_option_id: str
    explanation: str
    is_phishing: bool

class AnswerSubmit(BaseModel):
    question_id: str
    selected_option_id: str

class SimulationProgress(BaseModel):
    simulation_id: str
    progress: int
    completed: bool

class ChatMessage(BaseModel):
    message: str
    history: Optional[List[dict]] = []

class UserStatsUpdate(BaseModel):
    xp_gained: int
    correct: bool
    category: str
    
