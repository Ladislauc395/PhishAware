from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.database import get_db
from app.db_models import SimulationProgress as SimProgDB, QuizHistory

router = APIRouter()

SIMULATIONS = [
    {
        "id": "sim_1",
        "title": "E-mail Falso do Banco",
        "description": "Recebes um e-mail urgente do teu banco pedindo confirmação de dados. Aprende a distinguir comunicações legítimas de fraudes bancárias por email.",
        "threat_type": "Phishing Bancário",
        "real_impact": "Roubo de credenciais e acesso à conta bancária",
        "category": "email",
        "difficulty": "Fácil",
        "xp": 100,
        "question_ids": ["q1", "q2"],
        "tips": ["Verifica sempre o domínio do remetente", "Bancos nunca pedem senhas por email"],
    },
    {
        "id": "sim_2",
        "title": "Smishing: Entrega Retida CTT",
        "description": "SMS a dizer que tens uma encomenda retida na alfândega com taxa pendente. Um golpe extremamente comum em Portugal com milhares de vítimas por mês.",
        "threat_type": "Smishing (SMS Phishing)",
        "real_impact": "Roubo de dados de cartão de crédito",
        "category": "sms",
        "difficulty": "Médio",
        "xp": 200,
        "question_ids": ["q3", "q4"],
        "tips": ["CTT nunca cobram por SMS", "Rastreia sempre em ctt.pt diretamente"],
    },
    {
        "id": "sim_3",
        "title": "Site Falso Netflix/Streaming",
        "description": "Um link que parece legítimo leva-te a um clone perfeito do Netflix. Aprende a analisar URLs e identificar sites clonados que roubam credenciais.",
        "threat_type": "Clone de Website",
        "real_impact": "Roubo de senha e dados de pagamento",
        "category": "url",
        "difficulty": "Médio",
        "xp": 200,
        "question_ids": ["q5", "q6"],
        "tips": ["HTTPS não significa seguro", "O domínio real está sempre antes do primeiro /"],
    },
    {
        "id": "sim_4",
        "title": "App Falsa & QR Code Malicioso",
        "description": "Encontras uma app com 50k downloads e um QR code num restaurante que pede permissões suspeitas. Casos reais reportados em Lisboa e Porto em 2024.",
        "threat_type": "Malware Mobile",
        "real_impact": "Acesso a SMS, contactos e localização em tempo real",
        "category": "app",
        "difficulty": "Difícil",
        "xp": 300,
        "question_ids": ["q7", "q8"],
        "tips": ["Menos permissões = mais segurança", "QR codes públicos podem ser manipulados"],
    },
    {
        "id": "sim_5",
        "title": "Spear Phishing Corporativo",
        "description": "Ataques direcionados com o teu nome real, empresa e contexto profissional. O tipo de ataque que compromete empresas inteiras — 91% dos ciberataques começam assim.",
        "threat_type": "Spear Phishing Avançado",
        "real_impact": "Comprometimento corporativo, ransomware, extorsão",
        "category": "email",
        "difficulty": "Difícil",
        "xp": 400,
        "question_ids": ["q9", "q10"],
        "tips": ["Informação correta não significa email legítimo", "Verifica sempre notificações diretamente na plataforma"],
    },
]

class SimProgressBody(BaseModel):
    simulation_id: str
    progress: int
    completed: bool
    user_id: int = 1

@router.get("/")
def get_simulations(user_id: int = Query(default=1), db: Session = Depends(get_db)):
    result = []
    for sim in SIMULATIONS:
        prog = (db.query(SimProgDB)
                  .filter(SimProgDB.user_id == user_id,
                          SimProgDB.simulation_id == sim["id"])
                  .first())
        result.append({
            **sim,
            "progress":  prog.progress  if prog else 0,
            "completed": prog.completed if prog else False,
        })
    return result

@router.post("/{sim_id}/progress")
def update_progress(sim_id: str, body: SimProgressBody,
                    db: Session = Depends(get_db)):
    prog = (db.query(SimProgDB)
              .filter(SimProgDB.user_id == body.user_id,
                      SimProgDB.simulation_id == sim_id)
              .first())
    if prog:
        prog.progress  = body.progress
        prog.completed = body.completed
    else:
        prog = SimProgDB(user_id=body.user_id, simulation_id=sim_id,
                         progress=body.progress, completed=body.completed)
        db.add(prog)
    db.commit()
    return {"ok": True}
