from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime,timezone
from app.database import Base

class User(Base):
    __tablename__ = "users"
    id            = Column(Integer, primary_key=True, index=True)
    name          = Column(String, nullable=False)
    email         = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    avatar_letter = Column(String, default="U")
    created_at    = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    stats    = relationship("UserStats",       back_populates="user", uselist=False, cascade="all, delete")
    history  = relationship("QuizHistory",     back_populates="user", cascade="all, delete")
    sim_prog = relationship("SimulationProgress", back_populates="user", cascade="all, delete")

class UserStats(Base):
    __tablename__ = "user_stats"
    id             = Column(Integer, primary_key=True)
    user_id        = Column(Integer, ForeignKey("users.id"), unique=True)
    xp             = Column(Integer, default=0)
    resilience     = Column(Integer, default=0)
    level          = Column(String, default="Iniciante")
    correct_total  = Column(Integer, default=0)
    answered_total = Column(Integer, default=0)
    by_category    = Column(JSON, default={"email": 0, "sms": 0, "url": 0, "app": 0})
    show_in_ranking  = Column(Boolean, default=True)
    user = relationship("User", back_populates="stats")

class QuizHistory(Base):
    __tablename__ = "quiz_history"
    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    question_id = Column(String)
    category    = Column(String)
    is_correct  = Column(Boolean)
    points      = Column(Integer, default=0)
    scenario    = Column(String, default="")
    timestamp   = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="history")

class SimulationProgress(Base):
    __tablename__ = "simulation_progress"
    id            = Column(Integer, primary_key=True)
    user_id       = Column(Integer, ForeignKey("users.id"))
    simulation_id = Column(String)
    progress      = Column(Integer, default=0)
    completed     = Column(Boolean, default=False)

    user = relationship("User", back_populates="sim_prog")

class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"
    id         = Column(Integer, primary_key=True)
    email      = Column(String, index=True)
    code       = Column(String)
    expires_at = Column(DateTime)
    used       = Column(Boolean, default=False)
