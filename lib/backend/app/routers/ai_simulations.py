"""
app/routers/ai_simulations.py

Geração de simulações de phishing ULTRA-REALISTAS via Groq.
Tipos: email | sms | whatsapp | login_page | url
Inclui: brand_color, logo_url, suspicious_elements (tocáveis), layout_data
Chave Groq lida de .env — cliente nunca a vê.
"""

import os
import re
import json
import random
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter()



class GenerateRequest(BaseModel):
    type: Optional[str] = None         
    difficulty: Optional[str] = None  
    is_phishing: Optional[bool] = None 


class SuspiciousElement(BaseModel):
    id: str          
    label: str       
    hint: str        
    is_suspicious: bool
    element_type: str 


class ScenarioResponse(BaseModel):
    type: str
    is_phishing: bool
    difficulty: str
    brand: str
    brand_color: str         
    logo_url: str           
    logo_alt_text: str      
    sender_name: str
    sender_address: str
    subject: str
    preview_text: str
    body: str
    cta_text: str
    cta_url: str
    timestamp: str
    phone_number: Optional[str] = None   
    page_title: Optional[str] = None    
    form_fields: List[str] = [] 
    suspicious_elements: List[SuspiciousElement]
    red_flags: List[str]
    green_flags: List[str]
    explanation: str
    attack_technique: str
    real_world_reference: str
    potential_damage: str
    forensic_tip: str
    difficulty_reason: str



BRANDS = {
    "PayPal":    {"color": "#003087", "logo": "https://logo.clearbit.com/paypal.com",     "domain": "paypal.com"},
    "Amazon":    {"color": "#FF9900", "logo": "https://logo.clearbit.com/amazon.com",     "domain": "amazon.com"},
    "Microsoft": {"color": "#00A4EF", "logo": "https://logo.clearbit.com/microsoft.com",  "domain": "microsoft.com"},
    "Apple":     {"color": "#555555", "logo": "https://logo.clearbit.com/apple.com",      "domain": "apple.com"},
    "Google":    {"color": "#4285F4", "logo": "https://logo.clearbit.com/google.com",     "domain": "google.com"},
    "Netflix":   {"color": "#E50914", "logo": "https://logo.clearbit.com/netflix.com",    "domain": "netflix.com"},
    "DHL":       {"color": "#FFCC00", "logo": "https://logo.clearbit.com/dhl.com",        "domain": "dhl.com"},
    "Spotify":   {"color": "#1DB954", "logo": "https://logo.clearbit.com/spotify.com",    "domain": "spotify.com"},
    "Instagram": {"color": "#C13584", "logo": "https://logo.clearbit.com/instagram.com",  "domain": "instagram.com"},
    "LinkedIn":  {"color": "#0077B5", "logo": "https://logo.clearbit.com/linkedin.com",   "domain": "linkedin.com"},
    "WhatsApp":  {"color": "#25D366", "logo": "https://logo.clearbit.com/whatsapp.com",   "domain": "whatsapp.com"},
    "Nubank":    {"color": "#8A05BE", "logo": "https://logo.clearbit.com/nubank.com.br",  "domain": "nubank.com.br"},
    "Itaú":      {"color": "#EC7000", "logo": "https://logo.clearbit.com/itau.com.br",    "domain": "itau.com.br"},
    "Bradesco":  {"color": "#CC0000", "logo": "https://logo.clearbit.com/bradesco.com.br","domain": "bradesco.com.br"},
    "Banco BPI": {"color": "#003B8E", "logo": "https://logo.clearbit.com/bancobpi.pt",    "domain": "bancobpi.pt"},
    "EDP":       {"color": "#E2001A", "logo": "https://logo.clearbit.com/edp.pt",         "domain": "edp.pt"},
    "CTT":       {"color": "#DA2027", "logo": "https://logo.clearbit.com/ctt.pt",         "domain": "ctt.pt"},
    "Vodafone":  {"color": "#E60000", "logo": "https://logo.clearbit.com/vodafone.com",   "domain": "vodafone.com"},
    "NOS":       {"color": "#FF6B00", "logo": "https://logo.clearbit.com/nos.pt",         "domain": "nos.pt"},
    "MB WAY":    {"color": "#FF5C00", "logo": "https://logo.clearbit.com/mbway.pt",       "domain": "mbway.pt"},
}

TYPES = ["email", "sms", "whatsapp", "login_page", "url"]
DIFFS = ["easy", "medium", "hard"]
def _build_prompt(sim_type: str, difficulty: str, is_phishing: bool,
                  brand: str, bdata: dict) -> str:

    type_labels = {
        "email":      "email de phishing",
        "sms":        "SMS/smishing",
        "whatsapp":   "mensagem WhatsApp",
        "login_page": "página de login falsa",
        "url":        "URL/link malicioso analisado num browser",
    }

    diff_guidance = ""
    if is_phishing:
        diff_guidance = {
            "easy": (
                "DIFICULDADE FÁCIL — sinais óbvios:\n"
                f"- Domínio claramente falso (ex: {bdata['domain'].split('.')[0]}-security-alert.xyz)\n"
                "- Erros ortográficos na mensagem\n"
                "- Urgência extrema ('a tua conta será eliminada em 2h!')\n"
                "- Pedido explícito de password / dados bancários"
            ),
            "medium": (
                "DIFICULDADE MÉDIA — 2-3 sinais moderados:\n"
                f"- Domínio parecido mas diferente (ex: {bdata['domain'].split('.')[0]}-login.com)\n"
                "- Linguagem quase certa com 1-2 erros\n"
                "- Urgência moderada"
            ),
            "hard": (
                "DIFICULDADE DIFÍCIL — quase perfeito, só 1 sinal subtil:\n"
                "- Typosquatting (ex: paypa1.com com número 1 em vez de l)\n"
                "- Corpo da mensagem impecável\n"
                "- Técnica avançada: email spoofing, homógrafo Unicode, look-alike domain"
            ),
        }.get(difficulty, "")

    legit_note = (
        f"MENSAGEM LEGÍTIMA: usa domínio oficial {bdata['domain']}, linguagem profissional, sem urgência falsa."
        if not is_phishing else ""
    )

    form_fields_hint = (
        '"form_fields": ["Email", "Senha", "Confirmar Senha"]'
        if sim_type == "login_page" and is_phishing
        else '"form_fields": ["Email", "Senha"]'
        if sim_type == "login_page"
        else '"form_fields": []'
    )

    return f"""
Cria uma simulação educativa ULTRA-REALISTA de {type_labels.get(sim_type, 'email')} \
{"de PHISHING" if is_phishing else "LEGÍTIMA"} para treino de cibersegurança.

Marca: {brand} | Cor oficial: {bdata['color']} | Domínio real: {bdata['domain']} | Ano: 2025
{diff_guidance}
{legit_note}

Retorna APENAS JSON válido (sem markdown, sem comentários) com este esquema:
{{
  "type": "{sim_type}",
  "is_phishing": {str(is_phishing).lower()},
  "difficulty": "{difficulty}",
  "brand": "{brand}",
  "brand_color": "{bdata['color']}",
  "logo_url": "{bdata['logo']}",
  "logo_alt_text": "{"[nome da marca ligeiramente errado se phishing, ex: PayPa1]" if is_phishing else brand}",
  "sender_name": "Nome do remetente",
  "sender_address": "{"email@domínio-FALSO.com ou número falso" if is_phishing else f"no-reply@{bdata['domain']}"}",
  "subject": "Assunto da mensagem",
  "preview_text": "Texto preview curto (max 50 chars)",
  "body": "Corpo completo realista. Use \\n para quebras de linha.",
  "cta_text": "Texto do botão/link principal",
  "cta_url": "{"URL FALSA realista" if is_phishing else f"https://{bdata['domain']}"}",
  "timestamp": "Ex: 14:32",
  "phone_number": "+351912345678" if sim_type in ["sms", "whatsapp"] else null,
  "page_title": "{brand} — Iniciar Sessão" if sim_type == "login_page" else null,
  {form_fields_hint},
  "suspicious_elements": [
    {{
      "id": "sender",
      "label": "endereço completo do remetente",
      "hint": "{"Explicação técnica de por que este remetente é falso" if is_phishing else "Remetente oficial verificado"}",
      "is_suspicious": {"true" if is_phishing else "false"},
      "element_type": "sender"
    }},
    {{
      "id": "cta_url",
      "label": "URL/link do botão",
      "hint": "{"Análise do domínio falso — técnica usada" if is_phishing else "Domínio oficial verificado"}",
      "is_suspicious": {"true" if is_phishing else "false"},
      "element_type": "url"
    }},
    {{
      "id": "urgency_text",
      "label": "texto com urgência ou ameaça",
      "hint": "{"Tática de pressão para impedir reflexão crítica" if is_phishing else "Tom neutro e profissional"}",
      "is_suspicious": {"true" if is_phishing else "false"},
      "element_type": "body_text"
    }}
  ],
  "red_flags": {json.dumps(["sinal 1", "sinal 2", "sinal 3"]) if is_phishing else "[]"},
  "green_flags": {json.dumps(["indicador 1", "indicador 2"]) if not is_phishing else "[]"},
  "explanation": "Análise técnica detalhada. Mínimo 3 frases.",
  "attack_technique": "{"Técnica (ex: Brand Impersonation, Typosquatting)" if is_phishing else "N/A"}",
  "real_world_reference": "Caso real similar documentado",
  "potential_damage": "{"Impacto se a vítima cair" if is_phishing else "Não aplicável"}",
  "forensic_tip": "Dica técnica de verificação",
  "difficulty_reason": "Por que este exemplo tem esta dificuldade"
}}
""".strip()
def _extract_json(raw: str) -> dict:
    s = raw.strip()
    if s.startswith("```"):
        parts = s.split("```")
        s = parts[1] if len(parts) >= 2 else s
        s = s.lstrip("json").strip()
    s = re.sub(r'//[^\n"]*', '', s)
    start = s.find("{")
    end = s.rfind("}")
    if start >= 0 and end > start:
        s = s[start:end + 1]
    return json.loads(s)


@router.post("/generate", response_model=ScenarioResponse)
async def generate_simulation(body: GenerateRequest):
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="GROQ_API_KEY não configurada no servidor.",
        )

    sim_type    = body.type or random.choice(TYPES)
    difficulty  = body.difficulty or random.choice(DIFFS)
    brand       = random.choice(list(BRANDS.keys()))
    bdata       = BRANDS[brand]
    is_phishing = (
        body.is_phishing
        if body.is_phishing is not None
        else (random.random() < 0.70)
    )

    prompt = _build_prompt(sim_type, difficulty, is_phishing, brand, bdata)

    try:
        from groq import Groq
        client = Groq(api_key=api_key)
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "És um especialista sénior em cibersegurança criando simulações "
                        "ULTRA-REALISTAS para treino educativo. Os cenários devem ser "
                        "indistinguíveis de mensagens reais. "
                        "Responde SEMPRE e SOMENTE com JSON válido, sem markdown, "
                        "sem comentários, sem texto fora do JSON."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.85,
            max_tokens=2200,
        )

        raw_content = response.choices[0].message.content or "{}"
        data = _extract_json(raw_content)

        data.setdefault("type",                sim_type)
        data.setdefault("is_phishing",         is_phishing)
        data.setdefault("difficulty",          difficulty)
        data.setdefault("brand",               brand)
        data.setdefault("brand_color",         bdata["color"])
        data.setdefault("logo_url",            bdata["logo"])
        data.setdefault("logo_alt_text",       brand)
        data.setdefault("sender_name",         brand)
        data.setdefault("sender_address",      f"no-reply@{bdata['domain']}")
        data.setdefault("subject",             "Mensagem importante")
        data.setdefault("preview_text",        "")
        data.setdefault("body",                "")
        data.setdefault("cta_text",            "Clique Aqui")
        data.setdefault("cta_url",             f"https://{bdata['domain']}")
        data.setdefault("timestamp",           "Agora")
        data.setdefault("phone_number",        None)
        data.setdefault("page_title",          None)
        data.setdefault("form_fields",         [])
        data.setdefault("red_flags",           [])
        data.setdefault("green_flags",         [])
        data.setdefault("explanation",         "")
        data.setdefault("attack_technique",    "N/A")
        data.setdefault("real_world_reference","")
        data.setdefault("potential_damage",    "Não aplicável")
        data.setdefault("forensic_tip",        "")
        data.setdefault("difficulty_reason",   "")

        if isinstance(data.get("is_phishing"), str):
            data["is_phishing"] = data["is_phishing"].lower() == "true"

        raw_els = data.get("suspicious_elements", [])
        clean_els = []
        for el in raw_els:
            if isinstance(el, dict):
                clean_els.append({
                    "id":           str(el.get("id", "element")),
                    "label":        str(el.get("label", "")),
                    "hint":         str(el.get("hint", "")),
                    "is_suspicious": bool(el.get("is_suspicious", is_phishing)),
                    "element_type": str(el.get("element_type", "body_text")),
                })
        if not clean_els:
            clean_els = [
                {
                    "id": "sender",
                    "label": data["sender_address"],
                    "hint": "Verifica o domínio do remetente",
                    "is_suspicious": is_phishing,
                    "element_type": "sender",
                },
                {
                    "id": "cta_url",
                    "label": data["cta_url"],
                    "hint": "Analisa o domínio antes de clicar",
                    "is_suspicious": is_phishing,
                    "element_type": "url",
                },
            ]
        data["suspicious_elements"] = clean_els

        return ScenarioResponse(**data)

    except HTTPException:
        raise
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=500, detail=f"IA retornou JSON inválido: {e}")
    except Exception as e:
        err = str(e)
        if "429" in err:
            raise HTTPException(status_code=429, detail="Limite de pedidos Groq atingido. Aguarda um momento.")
        if "401" in err or "invalid_api_key" in err.lower():
            raise HTTPException(status_code=401, detail="Chave Groq inválida no servidor.")
        raise HTTPException(status_code=500, detail=f"Erro ao gerar simulação: {err}")