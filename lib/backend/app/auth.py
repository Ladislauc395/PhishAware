from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.database import get_db
from app.db_models import User, UserStats, PasswordResetCode
import hashlib, os, random, string
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import resend
from app.db_models import User, UserStats, QuizHistory
router = APIRouter()

def _hash(password: str) -> str:
    salt = os.getenv("SECRET_SALT", "phishaware_salt_2024")
    return hashlib.sha256(f"{salt}{password}".encode()).hexdigest()

def _send_email(to: str, code: str) -> bool:
    gmail_user = os.getenv("GMAIL_USER")       # teu email Gmail
    gmail_password = os.getenv("GMAIL_APP_PASSWORD")  # senha de aplicação

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "PhishAware — Código de Recuperação"
        msg["From"] = gmail_user
        msg["To"] = to

        html = f"""
        <div style="font-family:Arial;background:#0F1318;color:#E2E8F0;
             padding:32px;border-radius:16px">
          <h2 style="color:#00E5A0">🛡️ PhishAware</h2>
          <p>O teu código de recuperação é:</p>
          <div style="font-size:42px;font-weight:bold;letter-spacing:12px;
               color:#00E5A0;padding:24px;background:#1A2030;
               border-radius:12px;text-align:center">{code}</div>
          <p style="color:#64748B">Expira em 15 minutos.</p>
        </div>
        """
        msg.attach(MIMEText(html, "html"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(gmail_user, gmail_password)
            server.sendmail(gmail_user, to, msg.as_string())
        return True
    except Exception as e:
        print(f"[EMAIL ERROR] {e}")
        return False

class RegisterBody(BaseModel):
    name: str
    email: str
    password: str

class LoginBody(BaseModel):
    email: str
    password: str

class ForgotBody(BaseModel):
    email: str

class VerifyCodeBody(BaseModel):
    email: str
    code: str

class ResetPasswordBody(BaseModel):
    email: str
    code: str
    new_password: str


@router.post("/register")
def register(body: RegisterBody, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email já registado.")
    user = User(
        name=body.name,
        email=body.email,
        password_hash=_hash(body.password),
        avatar_letter=body.name[0].upper() if body.name else "U",
    )
    db.add(user)
    db.flush()
    db.add(UserStats(user_id=user.id))
    db.commit()
    db.refresh(user)
    return {"id": user.id, "name": user.name, "email": user.email,
            "avatar_letter": user.avatar_letter}

@router.post("/login")
def login(body: LoginBody, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email).first()
    if not user or user.password_hash != _hash(body.password):
        raise HTTPException(status_code=401, detail="Email ou senha incorretos.")
    stats = user.stats
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "avatar_letter": user.avatar_letter,
        "xp": stats.xp if stats else 0,
        "level": stats.level if stats else "Iniciante",
    }

@router.post("/forgot-password")
def forgot_password(body: ForgotBody, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email).first()
    if not user:
        # Respond OK to prevent email enumeration
        return {"ok": True, "message": "Se o email existir, receberás um código."}
    code = "".join(random.choices(string.digits, k=6))
    expires = datetime.now() + timedelta(minutes=15)
    # Invalidate old codes
    db.query(PasswordResetCode).filter(
        PasswordResetCode.email == body.email, PasswordResetCode.used == False
    ).update({"used": True})
    db.add(PasswordResetCode(email=body.email, code=code, expires_at=expires))
    db.commit()
    _send_email(body.email, code)
    return {"ok": True, "message": "Se o email existir, receberás um código."}

@router.post("/verify-code")
def verify_code(body: VerifyCodeBody, db: Session = Depends(get_db)):
    reset = db.query(PasswordResetCode).filter(
        PasswordResetCode.email == body.email,
        PasswordResetCode.code  == body.code,
        PasswordResetCode.used  == False,
        PasswordResetCode.expires_at > datetime.utcnow(),
    ).first()
    if not reset:
        raise HTTPException(status_code=400, detail="Código inválido ou expirado.")
    return {"ok": True}

@router.post("/reset-password")
def reset_password(body: ResetPasswordBody, db: Session = Depends(get_db)):
    reset = db.query(PasswordResetCode).filter(
        PasswordResetCode.email == body.email,
        PasswordResetCode.code  == body.code,
        PasswordResetCode.used  == False,
        PasswordResetCode.expires_at > datetime.utcnow(),
    ).first()
    if not reset:
        raise HTTPException(status_code=400, detail="Código inválido ou expirado.")
    user = db.query(User).filter(User.email == body.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilizador não encontrado.")
    user.password_hash = _hash(body.new_password)
    reset.used = True
    db.commit()
    return {"ok": True}
## Adiciona este endpoint ao ficheiro auth.py do backend
## (ou ao ficheiro onde tens os outros endpoints de autenticação)

## 1. No ficheiro auth.py — adiciona no final:



@router.delete("/delete-account/{user_id}")
def delete_account(user_id: int, db: Session = Depends(get_db)):
    """
    Elimina permanentemente a conta do utilizador e todos os dados associados.
    Apaga na ordem certa para respeitar as foreign keys.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Utilizador não encontrado")

    # 1. Elimina histórico
    db.query(QuizHistory).filter(QuizHistory.user_id == user_id).delete()

    # 2. Elimina stats
    db.query(UserStats).filter(UserStats.user_id == user_id).delete()

    # 3. Elimina o utilizador
    db.delete(user)
    db.commit()

    return {"success": True, "message": "Conta eliminada com sucesso"}


## 2. No ficheiro api_service.dart do Flutter — adiciona este método:

## static Future<void> deleteAccount(int userId) async {
##   final res = await http.delete(
##     Uri.parse('$_base/auth/delete-account/$userId'),
##   );
##   if (res.statusCode != 200) {
##     throw Exception('Erro ao eliminar conta: ${res.statusCode}');
##   }
## }    
