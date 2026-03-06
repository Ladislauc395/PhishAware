import os
from dotenv import load_dotenv
load_dotenv()
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
import app.db_models  
from app.routers import chat, stats, simulations, ai_simulations, auth
from app.routers.quiz import router as quiz_router
from app.routers.advanced_sims import router as advanced_sims_router

Base.metadata.create_all(bind=engine)

app = FastAPI(title="PhishAware API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,              prefix="/auth",            tags=["Auth"])
app.include_router(chat.router,              prefix="/chat",            tags=["Chat"])
app.include_router(quiz_router,       prefix="/quiz",            tags=["Quiz"])
app.include_router(simulations.router,       prefix="/simulations",     tags=["Simulations"])
app.include_router(ai_simulations.router,    prefix="/ai-simulations",  tags=["AI Simulations"])
app.include_router(stats.router,             prefix="/stats",           tags=["Stats"])
app.include_router(advanced_sims_router)
@app.get("/")
def root():
    return {"status": "PhishAware API online"}
