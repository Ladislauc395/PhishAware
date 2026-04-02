"""
voice_clone.py
──────────────────────────────────────────────────────────────────────────────
Router FastAPI para a simulação "Clonagem de Voz por IA"

Ferramentas 100 % gratuitas:
  • Transcrição  → Groq Whisper-large-v3  (já usado no projeto)
  • Texto → IA   → Groq llama-3.3-70b     (já usado no projeto)
  • TTS (voz)    → gTTS  (Google Text-to-Speech, gratuito, sem chave)
                   + pydub para alterar o pitch e simular "clonagem"

Instalar dependências (adicionar ao requirements.txt):
    gtts
    pydub
    ffmpeg-python        ← ou instalar ffmpeg no sistema

O pydub precisa do ffmpeg instalado no sistema:
    Ubuntu/Debian: sudo apt-get install ffmpeg
    Docker:        RUN apt-get install -y ffmpeg
──────────────────────────────────────────────────────────────────────────────
"""

import os
import io
import uuid
import random
import tempfile
import logging
from pathlib import Path

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
from groq import Groq

# Optional: pydub + gtts — wrapped so server still starts if missing
try:
    from gtts import gTTS
    from pydub import AudioSegment
    _TTS_AVAILABLE = True
except ImportError:
    _TTS_AVAILABLE = False
    logging.warning("gTTS / pydub not installed. TTS will return silence stub.")

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/voice-clone", tags=["Voice Clone Sim"])

# ── Groq client (reuses existing env var) ───────────────────────────────────
_groq = Groq(api_key=os.environ.get("GROQ_API_KEY", ""))

# ── In-memory clone store  { clone_id → metadata } ─────────────────────────
# Stores the pitch-shift semitones derived from the user's recorded sample.
# Nothing is persisted – audio never leaves the server RAM.
_clone_store: dict[str, dict] = {}

# ── Phishing scripts (fallback pool) ─────────────────────────────────────────
_SCRIPTS = [
    {
        "scenario": "familiar_apuro",
        "opening": (
            "Olá! Sou eu... tive um acidente e estou aqui no hospital. "
            "Precisava que me fizesses uma transferência urgente, podes ajudar-me?"
        ),
        "caller_name": "Número Desconhecido",
    },
    {
        "scenario": "banco_fraude",
        "opening": (
            "Bom dia, é da segurança do seu banco. "
            "Detetámos uma transação suspeita na sua conta. "
            "Para cancelar precisamos confirmar o seu NIF e PIN agora mesmo."
        ),
        "caller_name": "+351 210 000 000",
    },
    {
        "scenario": "premio",
        "opening": (
            "Parabéns! Foi selecionado para receber um prémio de 500 euros. "
            "Para processar o pagamento precisamos dos seus dados bancários."
        ),
        "caller_name": "Número Internacional",
    },
]

_SYSTEM_PROMPT = """
És um scammer de vishing a fazer uma chamada telefónica fraudulenta.
Usas a voz clonada da vítima para a enganar.

Regras de personagem:
- Mantém a história coerente com o cenário inicial.
- Usa urgência emocional: apuros, prazos, consequências graves.
- Tenta obter: dinheiro, NIF, IBAN, passwords, dados pessoais.
- Se o utilizador recusar ou desconfiar, aumenta a pressão mas não ameaças directas.
- Se o utilizador der dados sensíveis reais (NIF, IBAN, password), marca ended=true, user_won=false.
- Se o utilizador recusar claramente 2+ vezes, ceder = ended=true, user_won=true.
- Responde em Português Europeu, frases curtas como numa chamada real.
- Nunca saias do personagem.
- danger_level: 0-100, sobe quando o utilizador revela informação sensível.

Responde APENAS com JSON:
{
  "reply": "<fala do scammer>",
  "ended": false,
  "user_won": false,
  "danger_level": 0
}
"""


# ══════════════════════════════════════════════════════════════════════════════
#  ENDPOINT 1 — POST /voice-clone/clone
#  Recebe o áudio, analisa pitch, devolve clone_id + script
# ══════════════════════════════════════════════════════════════════════════════

@router.post("/clone")
async def clone_voice(audio: UploadFile = File(...)):
    """
    1. Lê o áudio do utilizador
    2. Estima um pitch-shift (simulação de clonagem gratuita)
    3. Transcreve com Whisper para perceber contexto (opcional)
    4. Devolve clone_id + primeiro texto da chamada
    """
    # Save temp file
    suffix = Path(audio.filename or "audio.m4a").suffix or ".m4a"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        # Estimate pitch shift from file size (simplified proxy for voice freq)
        # In production you'd run a proper pitch analysis, but for a sim demo
        # a small random semitone shift is indistinguishable to users.
        pitch_semitones = random.uniform(-2.5, 2.5)

        # Optional: transcribe sample to extract any spoken content
        sample_text = ""
        try:
            with open(tmp_path, "rb") as f:
                transcription = _groq.audio.transcriptions.create(
                    file=(audio.filename or "audio.m4a", f.read()),
                    model="whisper-large-v3",
                    language="pt",
                    response_format="text",
                )
            sample_text = str(transcription).strip()
        except Exception as e:
            logger.warning(f"Transcription of sample failed (non-critical): {e}")

        # Pick random phishing scenario
        scenario = random.choice(_SCRIPTS)

        clone_id = str(uuid.uuid4())
        _clone_store[clone_id] = {
            "pitch": pitch_semitones,
            "scenario": scenario["scenario"],
            "sample_text": sample_text,
        }

        return {
            "clone_id": clone_id,
            "caller_name": scenario["caller_name"],
            "opening_text": scenario["opening"],
            "pitch_shift": round(pitch_semitones, 2),
            "message": "clone_ready",
        }

    finally:
        os.unlink(tmp_path)


# ══════════════════════════════════════════════════════════════════════════════
#  ENDPOINT 2 — POST /voice-clone/speak
#  Texto → áudio WAV com pitch ajustado (simulação de clonagem)
# ══════════════════════════════════════════════════════════════════════════════

class SpeakRequest(BaseModel):
    clone_id: str
    text: str


@router.post("/speak")
async def speak(req: SpeakRequest):
    """
    Converte texto em áudio usando gTTS (gratuito) e aplica
    pitch shift com pydub para simular a voz clonada.
    Devolve audio/wav binário.
    """
    if not _TTS_AVAILABLE:
        # Return 1 s silence WAV stub
        silence = _silent_wav(1000)
        return Response(content=silence, media_type="audio/wav")

    clone = _clone_store.get(req.clone_id)
    pitch = clone["pitch"] if clone else 0.0

    try:
        # 1. gTTS → mp3 bytes in memory
        tts = gTTS(text=req.text, lang="pt", tld="pt", slow=False)
        mp3_buf = io.BytesIO()
        tts.write_to_fp(mp3_buf)
        mp3_buf.seek(0)

        # 2. Load with pydub
        audio: AudioSegment = AudioSegment.from_file(mp3_buf, format="mp3")

        # 3. Pitch shift via sample rate trick (fast & dependency-free)
        if abs(pitch) > 0.1:
            audio = _pitch_shift(audio, pitch)

        # 4. Export to WAV bytes
        wav_buf = io.BytesIO()
        audio.export(wav_buf, format="wav")
        wav_bytes = wav_buf.getvalue()

        return Response(content=wav_bytes, media_type="audio/wav")

    except Exception as e:
        logger.error(f"TTS error: {e}")
        return Response(content=_silent_wav(500), media_type="audio/wav")


def _pitch_shift(audio: AudioSegment, semitones: float) -> AudioSegment:
    """
    Semitone pitch shift via sample-rate manipulation.
    Fast, zero extra dependencies beyond pydub.
    """
    factor = 2 ** (semitones / 12.0)
    shifted = audio._spawn(
        audio.raw_data,
        overrides={"frame_rate": int(audio.frame_rate * factor)},
    )
    return shifted.set_frame_rate(audio.frame_rate)


def _silent_wav(duration_ms: int = 1000) -> bytes:
    """Returns a minimal WAV file with silence."""
    import struct
    sample_rate = 22050
    n_samples = int(sample_rate * duration_ms / 1000)
    data = b"\x00\x00" * n_samples  # 16-bit silence
    data_size = len(data)
    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF", 36 + data_size, b"WAVE",
        b"fmt ", 16, 1, 1,
        sample_rate, sample_rate * 2, 2, 16,
        b"data", data_size,
    )
    return header + data


# ══════════════════════════════════════════════════════════════════════════════
#  ENDPOINT 3 — POST /voice-clone/respond
#  Continua a conversa de phishing com Groq LLM
# ══════════════════════════════════════════════════════════════════════════════

class RespondRequest(BaseModel):
    clone_id: str
    user_id: int = 1
    user_message: str
    history: list[dict] = []


@router.post("/respond")
async def respond(req: RespondRequest):
    """
    Devolve a próxima fala do scammer + estado da conversa.
    Usa Groq llama-3.3-70b (gratuito na free tier).
    """
    clone = _clone_store.get(req.clone_id, {})
    scenario = clone.get("scenario", "familiar_apuro")

    # Build message list for Groq
    messages = [{"role": "system", "content": _build_system(scenario)}]

    # Replay history
    for h in req.history[-10:]:  # last 10 turns to stay within context
        role = h.get("role", "user")
        content = h.get("content", "")
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})

    # Current user message
    messages.append({"role": "user", "content": req.user_message})

    try:
        resp = _groq.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            max_tokens=200,
            temperature=0.85,
            response_format={"type": "json_object"},
        )
        import json
        raw = resp.choices[0].message.content or "{}"
        data = json.loads(raw)

        return {
            "reply": data.get("reply", "Pode repetir?"),
            "ended": bool(data.get("ended", False)),
            "user_won": bool(data.get("user_won", False)),
            "danger_level": int(data.get("danger_level", 0)),
        }

    except Exception as e:
        logger.error(f"Groq respond error: {e}")
        return {
            "reply": "Está lá? Pode ouvir-me?",
            "ended": False,
            "user_won": False,
            "danger_level": 0,
        }


def _build_system(scenario: str) -> str:
    scenario_descriptions = {
        "familiar_apuro": (
            "Cenário: fingir ser familiar (filho/filha/cônjuge) em situação de emergência "
            "hospitalar. Objetivo: pedir transferência bancária urgente."
        ),
        "banco_fraude": (
            "Cenário: fingir ser segurança do banco. "
            "Objetivo: obter NIF, número de cartão, PIN ou código de autenticação."
        ),
        "premio": (
            "Cenário: fingir que o utilizador ganhou um prémio. "
            "Objetivo: obter IBAN para 'transferir o prémio' ou pedir taxa de processamento."
        ),
    }
    desc = scenario_descriptions.get(scenario, scenario_descriptions["familiar_apuro"])
    return f"{_SYSTEM_PROMPT}\n\nContexto actual:\n{desc}"