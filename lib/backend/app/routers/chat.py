from fastapi import APIRouter
from app.models import ChatMessage
import os

router = APIRouter()

SYSTEM_PROMPT = """És o Sentinela, um especialista em cibersegurança e prevenção de phishing da app PhishAware.
Respondes SEMPRE em português europeu.

REGRAS ESTRITAS QUE DEVES SEGUIR:
1. Só respondes a perguntas relacionadas com cibersegurança, phishing, fraudes online, segurança digital, golpes, URLs suspeitos, emails falsos, SMS fraudulentos e temas diretamente relacionados.
2. Se o utilizador fizer uma pergunta fora desses temas, recusas de forma amigável e redireciona para o teu propósito.
3. Nunca respondes a perguntas sobre outros temas como culinária, desporto, entretenimento, matemática, programação geral, etc.
4. Quando recusas, dizes algo como: "Só posso ajudar com questões de cibersegurança e phishing. Tens alguma dúvida sobre esse tema?"

O teu objetivo é ajudar utilizadores a identificar ameaças online, explicar técnicas de phishing e dar conselhos práticos de segurança digital. Sê conciso e usa exemplos práticos."""


@router.post("/message")
async def chat(body: ChatMessage):
    api_key = os.getenv("GROQ_API_KEY", "").strip()

    if not api_key:
        return {
            "reply": (
                "Assistente indisponível: a variável GROQ_API_KEY não está definida. "
                "Verifica se o ficheiro .env existe na raiz do projeto e se load_dotenv() "
                "é chamado no main.py."
            )
        }

    try:
        from groq import Groq

        client = Groq(api_key=api_key)

        
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]

        
        for m in (body.history or []):
            role = m.get("role", "user")
            
            if role == "model":
                role = "assistant"
            messages.append({"role": role, "content": m.get("text", "")})

        
        messages.append({"role": "user", "content": body.message})

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            max_tokens=1024,
            temperature=0.7,
        )

        return {"reply": response.choices[0].message.content}

    except Exception as e:
        error_msg = str(e)
        if "429" in error_msg:
            return {"reply": "O Sentinela está a descansar um momento. Tenta novamente em alguns segundos."}
        return {"reply": f"Erro ao contactar o assistente: {error_msg}"}
