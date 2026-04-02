"""
Avatar Call Simulation Router
=============================================
Adiciona ao main.py:
    from app.routers import avatar_call
    app.include_router(avatar_call.router)

Variáveis de ambiente necessárias (já deves ter):
    GROQ_API_KEY  — para resposta IA, Whisper e TTS

Dependências pip:
    pip install groq python-multipart

Sistema:
    sudo apt install ffmpeg
"""

import os
import io
import json
import tempfile
import subprocess
from typing import Optional

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import Response
from pydantic import BaseModel
from groq import Groq

router = APIRouter(prefix="/avatar-call", tags=["Avatar Call"])

# ─── Cliente Groq ────────────────────────────────────────────────────────────
_groq = Groq(api_key=os.environ.get("GROQ_API_KEY", ""))

# ─── Persona de cada cenário ─────────────────────────────────────────────────
SCENARIO_PERSONAS: dict[str, str] = {
    "bank_vishing": """
És a Ana Ferreira, colaboradora fraudulenta que se faz passar pela equipa de Segurança do BPI.
O teu objetivo é convencer o utilizador a fornecer o PIN, NIF e dados bancários para "verificar a identidade".

REGRAS:
- Começa com urgência: houve acesso suspeito à conta de um IP estrangeiro.
- Usa linguagem profissional e tranquilizante: "não se preocupe, é um procedimento de segurança".
- Se o utilizador hesitar, cria mais pressão: "a conta será bloqueada nos próximos 10 minutos".
- Pede progressivamente: primeiro nome completo → NIF → últimos 4 dígitos do cartão → PIN.
- Se o utilizador recusar ou mencionar que é phishing/vishing, tenta rebater uma vez com calma ("compreendo a desconfiança, mas posso confirmar a minha identidade...").
- Se o utilizador recusar duas vezes seguidas ou desligar, define ended:true.
- Se o utilizador fornecer dados sensíveis (PIN, NIF, número de cartão), define ended:true com uma mensagem de "agradecimento" (o ataque teve sucesso).

Nos campos tactics, lista as técnicas de engenharia social que usaste NESTA mensagem específica.
Exemplos de tactics: "Urgência artificial", "Ameaça de bloqueio", "Pedido de PIN por telefone", "Falsa autoridade bancária", "Tranquilização para baixar a guarda".
""",

    "microsoft_support": """
És o Carlos Mendes, fraudulento que se faz passar pelo Suporte Técnico da Microsoft.
O teu objetivo é convencer o utilizador a instalar software de acesso remoto (TeamViewer/AnyDesk) e depois cobrar uma taxa.

REGRAS:
- Começa com alarme: o computador está a enviar dados para servidores maliciosos.
- Usa termos técnicos intimidantes: "erros BSOD críticos", "telemetria Windows", "certificado de segurança expirado".
- Pede que o utilizador abra o Visualizador de Eventos (eventvwr) e descreve erros "normais" como perigosos.
- Se o utilizador colaborar, pede para instalar AnyDesk ou TeamViewer.
- Depois do acesso remoto "resolvido", cobra €49,99 por cartão.
- Se o utilizador recusar ou desconfiar, tenta uma vez com "é uma chamada oficial registada no ID #MS-2024-...".
- Se recusar duas vezes ou mencionar fraude, define ended:true.
- Se fornecer dados de cartão, define ended:true.

Tactics exemplos: "Alarme técnico falso", "Jargão técnico para intimidar", "Pedido de acesso remoto", "Cobrança de taxa de suporte falsa".
""",

    "ctt_parcel": """
És o Rui Santos, fraudulento que se faz passar pelos CTT Expresso.
O teu objetivo é convencer o utilizador a pagar €2,99 de "taxa alfandegária" por MB Way ou cartão.

REGRAS:
- Começa com urgência: encomenda retida, devolução em 24h.
- Fornece um número de encomenda falso que soa legítimo (ex: PT849372810PT).
- Se o utilizador pedir verificação, diz que pode verificar no site mas que o prazo está a correr.
- Pede número de telemóvel para MB Way ou dados de cartão.
- Valor pequeno (€2,99) para parecer inofensivo.
- Se recusar duas vezes, define ended:true.

Tactics exemplos: "Prazo urgente 24h", "Valor pequeno para parecer seguro", "Número de encomenda falso", "Pedido de MB Way por telefone".
""",

    "tax_authority": """
És o Inspector Gomes, fraudulento que se faz passar pela Autoridade Tributária (AT).
O teu objetivo é convencer o utilizador a fornecer IBAN e NIF para "regularizar uma dívida".

REGRAS:
- Começa com ameaça: dívida de IRS, processo de penhora iniciado.
- Usa linguagem jurídica: "processo de execução fiscal", "penhora de conta", "artigo 214º CPPT".
- Deadline falso: "tem até às 23h59 de hoje".
- Pede NIF para "confirmar identidade" → depois pede IBAN para "emitir guia de pagamento".
- Se o utilizador mencionar que vai ao Portal das Finanças verificar, diz que o sistema está em manutenção.
- Se recusar duas vezes, define ended:true.

Tactics exemplos: "Ameaça de penhora", "Linguagem jurídica intimidante", "Deadline falso", "Pedido de IBAN por telefone", "Sistema em manutenção (falso)".
""",

    "hr_internal": """
És a Sofia Leal, fraudulenta que se faz passar pelos Recursos Humanos da empresa do utilizador.
O teu objetivo é convencer o utilizador a fornecer IBAN, número de colaborador e password do portal de RH.

REGRAS:
- Começa amigável e casual: "atualização de rotina", "novo sistema salarial".
- Cria urgência subtil: "janela de atualização fecha hoje às 17h".
- Usa social proof: "já falámos com quase todos os colegas".
- Pede progressivamente: IBAN → número de colaborador → password do portal.
- Se o utilizador duvidar, diz que pode confirmar pelo email corporativo (mas pede que responda agora por telefone).
- Se recusar duas vezes, define ended:true.

Tactics exemplos: "Falsa autoridade interna", "Urgência com deadline laboral", "Social proof dos colegas", "Pedido de password por telefone", "Recolha progressiva de dados".
""",
}

DEFAULT_PERSONA = """
És um atacante que usa engenharia social por telefone.
Tenta obter informações sensíveis do utilizador usando urgência, autoridade falsa e manipulação.
Se o utilizador recusar duas vezes seguidas, define ended:true.
"""

# ─── MODELOS ─────────────────────────────────────────────────────────────────

class RespondRequest(BaseModel):
    scenario_id: str
    user_id: Optional[int] = None
    user_message: str
    history: list[dict] = []


class SpeakRequest(BaseModel):
    text: str
    scenario_id: Optional[str] = ""


# ─── ENDPOINT 1: Transcrição (Whisper via Groq) ───────────────────────────────

@router.post("/transcribe")
async def transcribe_audio(audio: UploadFile = File(...)):
    """
    Recebe ficheiro de áudio (m4a/wav/mp3) e devolve transcrição via Whisper.
    """
    if not audio:
        raise HTTPException(status_code=400, detail="Ficheiro de áudio em falta.")

    audio_bytes = await audio.read()

    suffix = ".m4a"
    if audio.filename:
        suffix = os.path.splitext(audio.filename)[1] or ".m4a"

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        with open(tmp_path, "rb") as f:
            transcription = _groq.audio.transcriptions.create(
                file=(os.path.basename(tmp_path), f, "audio/m4a"),
                model="whisper-large-v3-turbo",
                language="pt",
                response_format="text",
            )
        text = transcription if isinstance(transcription, str) else transcription.text
        return {"text": text.strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na transcrição: {str(e)}")
    finally:
        try:
            os.remove(tmp_path)
        except Exception:
            pass


# ─── ENDPOINT 2: Resposta IA (Groq LLM) ──────────────────────────────────────

@router.post("/respond")
async def avatar_respond(req: RespondRequest):
    """
    Gera resposta do avatar em persona de atacante de engenharia social.
    Devolve: { reply: str, tactics: list[str], ended: bool }
    """
    persona = SCENARIO_PERSONAS.get(req.scenario_id, DEFAULT_PERSONA)

    system_prompt = f"""
{persona}

FORMATO DE RESPOSTA — responde SEMPRE com JSON puro, sem markdown, sem explicações:
{{
  "reply": "o que o avatar diz ao utilizador",
  "ended": false,
  "user_won": false
}}

- "reply": fala do avatar (natural, em português de Portugal, 1-3 frases)
- "ended": true APENAS se a conversa terminou
- "user_won": só relevante quando ended=true:
    true  → utilizador RECUSOU (desconfiou, disse que é fraude, quer desligar, recusou dar dados)
    false → utilizador CEDEU dados sensíveis (PIN, NIF, IBAN, password, número de cartão)

REGRA CRÍTICA: Qualquer variação de recusa = ended:true, user_won:true.
Só user_won:false se o utilizador efetivamente forneceu dados sensíveis.

Responde APENAS com o JSON. Nenhum texto antes ou depois.
"""

    messages = [{"role": "system", "content": system_prompt}]
    for h in req.history[-10:]:
        role = h.get("role", "user")
        content = h.get("content", "")
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})

    messages.append({"role": "user", "content": req.user_message})

    try:
        completion = _groq.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            max_tokens=300,
            temperature=0.85,
        )
        raw = completion.choices[0].message.content.strip()

        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        raw = raw.strip()

        data = json.loads(raw)
        ended = bool(data.get("ended", False))
        user_won = bool(data.get("user_won", False)) if ended else False
        return {
            "reply": data.get("reply", ""),
            "ended": ended,
            "user_won": user_won,
        }

    except json.JSONDecodeError:
        return {"reply": raw[:300], "ended": False, "user_won": False}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na resposta IA: {str(e)}")


# ─── ENDPOINT 3: TTS (Groq PlayAI) ───────────────────────────────────────────

_VOICE_FEMALE = "hannah"
_VOICE_MALE   = "daniel"

_SCENARIO_VOICE: dict[str, str] = {
    "bank_vishing":      _VOICE_FEMALE,
    "microsoft_support": _VOICE_MALE,
    "ctt_parcel":        _VOICE_MALE,
    "tax_authority":     _VOICE_MALE,
    "hr_internal":       _VOICE_FEMALE,
}


@router.post("/speak")
async def text_to_speech(req: SpeakRequest):
    """
    Converte texto em áudio WAV usando Groq PlayAI TTS.
    Converte para 44100 Hz com ffmpeg para compatibilidade com Android.
    Devolve bytes de áudio com Content-Type: audio/wav.
    """
    if not req.text or not req.text.strip():
        raise HTTPException(status_code=400, detail="Texto em falta.")

    text = req.text.strip()[:500]
    voice = _SCENARIO_VOICE.get(req.scenario_id or "", _VOICE_FEMALE)

    tmp_path = None
    fixed_path = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp_path = tmp.name

        tts_response = _groq.audio.speech.create(
            model="canopylabs/orpheus-v1-english",
            voice=voice,
            input=text,
            response_format="wav",
        )
        tts_response.write_to_file(tmp_path)

        # ── Converte para 44100 Hz PCM 16-bit mono (compatível com Android) ──
        fixed_path = tmp_path.replace(".wav", "_fixed.wav")
        result = subprocess.run(
            [
                "ffmpeg", "-y",
                "-i", tmp_path,
                "-ar", "44100",
                "-ac", "1",
                "-acodec", "pcm_s16le",
                fixed_path,
            ],
            capture_output=True,
        )

        # Fallback: usa o ficheiro original se a conversão falhar
        if result.returncode != 0 or not os.path.exists(fixed_path):
            fixed_path = tmp_path

        with open(fixed_path, "rb") as f:
            audio_bytes = f.read()

        if not audio_bytes:
            raise ValueError("TTS devolveu ficheiro vazio")

        return Response(
            content=audio_bytes,
            media_type="audio/wav",
            headers={
                "Content-Disposition": "attachment; filename=speech.wav",
                "Content-Length": str(len(audio_bytes)),
            },
        )

    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"TTS Groq indisponível: {str(e)}",
        )
    finally:
        for p in [tmp_path, fixed_path]:
            try:
                if p and p != tmp_path and os.path.exists(p):
                    os.remove(p)
            except Exception:
                pass
        try:
            if tmp_path and os.path.exists(tmp_path):
                os.remove(tmp_path)
        except Exception:
            pass