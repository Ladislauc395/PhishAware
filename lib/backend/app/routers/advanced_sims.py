"""
advanced_sims.py  –  Router para simulações avançadas de phishing
Adicionar em app/routers/ e incluir em app/main.py:
    from app.routers.advanced_sims import router as advanced_sims_router
    app.include_router(advanced_sims_router)
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import random

router = APIRouter(prefix="/advanced-sims", tags=["Advanced Simulations"])

# ─── Models ──────────────────────────────────────────────────────────────────

class VishingScenario(BaseModel):
    id: str
    title: str
    caller_name: str
    caller_role: str
    company: str
    phone_number: str
    script_lines: list[str]       # falas do atacante
    audio_cues: list[str]         # descrições dos sons/ruídos
    red_flags: list[str]
    is_phishing: bool
    explanation: str
    difficulty: str

class SearchPhishingScenario(BaseModel):
    id: str
    search_query: str
    results: list[dict]           # lista de resultados de pesquisa
    target_result_index: int      # qual resultado é malicioso
    is_phishing: bool
    red_flags: list[str]
    explanation: str
    difficulty: str

class QuishingScenario(BaseModel):
    id: str
    context: str                  # onde foi encontrado o QR code
    qr_destination: str           # URL de destino (falso ou real)
    page_title: str
    page_fields: list[str]        # campos pedidos na página
    visual_hints: list[str]       # pistas visuais (adesivo colado, etc.)
    is_phishing: bool
    red_flags: list[str]
    explanation: str
    difficulty: str

class PharmingScenario(BaseModel):
    id: str
    typed_url: str
    displayed_url: str
    page_content: dict            # elementos da página falsa
    ssl_present: bool
    differences: list[str]        # diferenças subtis
    is_phishing: bool
    red_flags: list[str]
    explanation: str
    difficulty: str

class AnglerScenario(BaseModel):
    id: str
    platform: str                 # Twitter, Instagram, Facebook
    original_complaint: str
    fake_account: dict            # nome, handle, followers, verified
    reply_message: str
    support_link: str
    is_phishing: bool
    red_flags: list[str]
    explanation: str
    difficulty: str

class WhalingScenario(BaseModel):
    id: str
    target_role: str              # CEO, CFO, Diretor
    sender_name: str
    sender_role: str
    subject: str
    email_body: str
    urgency_level: str
    is_phishing: bool
    red_flags: list[str]
    explanation: str
    difficulty: str

class SimUserAnswer(BaseModel):
    sim_type: str
    sim_id: str
    user_answer: bool             # True = é phishing, False = legítimo
    user_id: int
    time_spent_seconds: Optional[int] = None

class SimResult(BaseModel):
    correct: bool
    xp_earned: int
    explanation: str
    correct_answer: bool

# ─── Dados estáticos (podem ser substituídos por Groq/AI em produção) ────────

_VISHING_SCENARIOS = [
    VishingScenario(
        id="v001",
        title="Chamada do Banco",
        caller_name="Ricardo Ferreira",
        caller_role="Segurança — Banco BPI",
        company="Banco BPI",
        phone_number="+351 21 000 1234",
        script_lines=[
            "Bom dia, fala o Ricardo Ferreira do departamento de segurança do Banco BPI.",
            "Detetámos uma tentativa de acesso suspeita na sua conta há 10 minutos.",
            "Para proteger os seus fundos, precisamos verificar a sua identidade.",
            "Por favor, diga-me o seu número de contribuinte e o PIN do seu cartão.",
            "É urgente — se não confirmar agora, a conta será bloqueada preventivamente.",
        ],
        audio_cues=[
            "Sons de escritório ao fundo",
            "Voz calma e profissional",
            "Silêncio breve antes de pedir o PIN",
            "Tom de urgência crescente",
        ],
        red_flags=[
            "Bancos NUNCA pedem o PIN por telefone",
            "Pressão de urgência artificial",
            "Número de telefone não verificável",
            "Pede dados sensíveis sem autenticação prévia",
        ],
        is_phishing=True,
        explanation="Este é um ataque de Vishing clássico. O atacante finge ser do banco e usa urgência para obter o PIN. Nenhuma instituição financeira legítima pede credenciais por telefone.",
        difficulty="medium"
    ),
    VishingScenario(
        id="v002",
        title="Suporte Técnico Microsoft",
        caller_name="John Smith",
        caller_role="Technical Support — Microsoft",
        company="Microsoft",
        phone_number="+1-800-642-7676",
        script_lines=[
            "Hello, this is John from Microsoft Technical Support.",
            "We detected that your Windows license has expired and your computer is at risk.",
            "I need to access your computer remotely to fix the issue.",
            "Please download AnyDesk and give me the access code.",
            "This will only take 5 minutes and it's completely free.",
        ],
        audio_cues=[
            "Sotaque estrangeiro ligeiro",
            "Ruído de call center ao fundo",
            "Tom insistente quando recusas",
        ],
        red_flags=[
            "Microsoft não contacta utilizadores proativamente",
            "Pede acesso remoto ao computador",
            "Ameaça com vírus/expiração de licença",
            "Número não pertence à Microsoft oficial",
        ],
        is_phishing=True,
        explanation="Fraude de suporte técnico. A Microsoft nunca liga para oferecer suporte não solicitado. O acesso remoto permitiria ao atacante instalar malware e roubar dados.",
        difficulty="easy"
    ),
    VishingScenario(
        id="v003",
        title="Confirmação de Entrega CTT",
        caller_name="Sistema Automático CTT",
        caller_role="Sistema de Rastreio — CTT",
        company="CTT",
        phone_number="+351 707 262 626",
        script_lines=[
            "Olá, este é um aviso automático dos CTT.",
            "Tem uma encomenda pendente de entrega para o seu endereço.",
            "Para confirmar a entrega, aceda a ctt-entrega-segura.pt",
            "Introduza o código de rastreio: PT123456789PT",
            "É necessário pagar 1,99€ de taxa de reimportação.",
        ],
        audio_cues=[
            "Voz sintetizada/robótica",
            "Música de espera institucional",
        ],
        red_flags=[
            "Domínio ctt-entrega-segura.pt não é oficial (ctt.pt é o correto)",
            "CTT não pede pagamentos por chamada",
            "Valor pequeno para baixar a guarda",
            "Não confirma dados da encomenda específicos",
        ],
        is_phishing=True,
        explanation="Smishing/Vishing combinado. O domínio falso imita os CTT. A cobrança de valor pequeno é uma tática para obter dados de cartão de crédito.",
        difficulty="hard"
    ),
]

_SEARCH_PHISHING_SCENARIOS = [
    SearchPhishingScenario(
        id="s001",
        search_query="login banco santander portugal",
        results=[
            {
                "position": 1,
                "title": "Santander Portugal — Acesso Netbanco [ANÚNCIO]",
                "url": "santander-netbanco-pt.com/login",
                "description": "Acesso rápido ao Netbanco Santander. Entre na sua conta agora.",
                "is_malicious": True,
                "badge": "Anúncio patrocinado",
            },
            {
                "position": 2,
                "title": "Santander Portugal | Particulares",
                "url": "santander.pt/particulares/netbanco",
                "description": "Netbanco Particulares — Gerencie as suas contas, transferências e muito mais.",
                "is_malicious": False,
                "badge": None,
            },
            {
                "position": 3,
                "title": "Como aceder ao Netbanco Santander — Guia 2024",
                "url": "dinheirovivo.pt/guias/netbanco-santander",
                "description": "Passo a passo para aceder ao Netbanco Santander em segurança.",
                "is_malicious": False,
                "badge": None,
            },
        ],
        target_result_index=0,
        is_phishing=True,
        red_flags=[
            "Domínio santander-netbanco-pt.com ≠ santander.pt",
            "É um anúncio pago — qualquer pessoa pode pagar",
            "Hifens e sufixos extra no domínio são sinal de alerta",
            "O resultado orgânico (posição 2) é o legítimo",
        ],
        explanation="Search Engine Phishing: anúncios pagos permitem a atacantes colocar sites falsos no topo dos resultados. Verifica sempre o domínio completo antes de clicar.",
        difficulty="medium"
    ),
    SearchPhishingScenario(
        id="s002",
        search_query="download adobe acrobat gratis",
        results=[
            {
                "position": 1,
                "title": "Adobe Acrobat Reader — Download Oficial",
                "url": "adobe.com/acrobat/pdf-reader",
                "description": "Descarrega o Adobe Acrobat Reader gratuitamente. Versão oficial e segura.",
                "is_malicious": False,
                "badge": None,
            },
            {
                "position": 2,
                "title": "Adobe Acrobat Pro GRÁTIS — Download 2024",
                "url": "adobe-acrobat-download.net/gratis-2024",
                "description": "Adobe Acrobat Pro completo, grátis! Sem registo. Download direto.",
                "is_malicious": True,
                "badge": None,
            },
            {
                "position": 3,
                "title": "Alternativas gratuitas ao Adobe Acrobat",
                "url": "pcmag.com/picks/best-free-pdf-editors",
                "description": "Os melhores editores PDF gratuitos testados pela PCMag.",
                "is_malicious": False,
                "badge": None,
            },
        ],
        target_result_index=1,
        is_phishing=True,
        red_flags=[
            "Domínio adobe-acrobat-download.net não é adobe.com",
            "Promessa de software pago de graça é sinal de alerta",
            "Sem necessidade de registo = sem rastreabilidade",
            "Software descarregado pode conter malware",
        ],
        explanation="SEO Phishing: sites otimizados para aparecer em pesquisas de software popular. O download pode conter ransomware ou spyware disfarçado.",
        difficulty="easy"
    ),
]

_QUISHING_SCENARIOS = [
    QuishingScenario(
        id="q001",
        context="Parquímetro na Baixa de Lisboa. Há um autocolante com QR Code colado por cima do QR Code original.",
        qr_destination="http://parking-lisboa-pay.tk/pagamento",
        page_title="Lisboa Parking — Pagamento Seguro",
        page_fields=["Número de matrícula", "Tempo de estacionamento", "Número de cartão de crédito", "CVV", "Data de validade"],
        visual_hints=[
            "O autocolante com o QR Code parece ligeiramente levantado nas bordas",
            "A superfície por baixo tem um QR Code diferente visível",
            "O domínio usa extensão .tk (Tokelau) — incomum para serviço municipal",
        ],
        is_phishing=True,
        red_flags=[
            "Domínio .tk não é oficial da Câmara Municipal",
            "QR Code colado sobre o original — sinal físico de adulteração",
            "Pede dados completos do cartão — sistemas legítimos usam pagamento por app",
            "URL usa HTTP (sem S) — sem encriptação",
        ],
        explanation="Quishing físico: autocolantes com QR Codes maliciosos são colocados sobre QR Codes legítimos em locais públicos. Verifica sempre se o QR Code parece adulterado.",
        difficulty="hard"
    ),
    QuishingScenario(
        id="q002",
        context="Restaurante. O menu tem um QR Code para ver a ementa digital.",
        qr_destination="https://restaurante-sabores.pt/ementa",
        page_title="Sabores do Porto — Ementa Digital",
        page_fields=["(apenas visualização da ementa — sem formulários)"],
        visual_hints=[
            "QR Code impresso diretamente no papel do menu",
            "O domínio corresponde ao nome do restaurante",
            "Página só mostra a ementa, sem pedir dados",
        ],
        is_phishing=False,
        red_flags=[],
        explanation="Este QR Code é legítimo. Apenas abre a ementa digital sem pedir dados pessoais ou de pagamento. QR Codes de menu são seguros quando não pedem informações.",
        difficulty="easy"
    ),
]

_PHARMING_SCENARIOS = [
    PharmingScenario(
        id="ph001",
        typed_url="www.cgd.pt",
        displayed_url="www.cgd.pt",
        page_content={
            "title": "Caixa Geral de Depósitos — Caixadirecta",
            "logo_color": "#E30613",
            "form_fields": ["NIF", "Código de acesso", "Código PIN"],
            "extra_field": "Número completo do cartão de débito",
            "ssl_icon": True,
            "footer": "© 2024 Caixa Geral de Depósitos, S.A.",
        },
        ssl_present=True,
        differences=[
            "O site original nunca pede o número completo do cartão no login",
            "O certificado SSL pertence a 'CGD Hosting Services' em vez de 'Caixa Geral de Depósitos'",
            "O campo 'Número do cartão de débito' não existe no site real",
            "Cores ligeiramente diferentes no botão de login (#E30613 vs #CC0000)",
        ],
        is_phishing=True,
        red_flags=[
            "Campo extra: número completo do cartão não é pedido no login real",
            "Certificado SSL pertence a entidade diferente",
            "DNS foi comprometido — URL parece correto mas servidor é falso",
            "Diferenças subtis no design (cores, tipografia)",
        ],
        explanation="Pharming por envenenamento de DNS. O URL parece correto mas o DNS foi manipulado para redirecionar para um servidor falso. Verifica sempre o certificado SSL clicando no cadeado.",
        difficulty="hard"
    ),
]

_ANGLER_SCENARIOS = [
    AnglerScenario(
        id="a001",
        platform="Twitter / X",
        original_complaint="@TAPAirPortugal o meu voo foi cancelado e ninguém me dá resposta! Já estou há 3h no aeroporto #TAP #cancelamento",
        fake_account={
            "name": "TAP Air Portugal Suporte",
            "handle": "@TAPSuporteOficial",
            "followers": "1.247",
            "verified": False,
            "created": "há 3 dias",
            "profile_pic": "logo TAP com fundo branco",
        },
        reply_message="Olá! Lamentamos o sucedido. Para resolver urgentemente, clique no link e preencha o formulário de compensação: tap-suporte-cliente.com/compensacao",
        support_link="tap-suporte-cliente.com/compensacao",
        is_phishing=True,
        red_flags=[
            "Handle @TAPSuporteOficial não é o oficial (@TAPAirPortugal)",
            "Conta criada há apenas 3 dias",
            "Não tem verificação (sem visto azul/dourado)",
            "Apenas 1.247 seguidores — conta oficial teria centenas de milhar",
            "Domínio tap-suporte-cliente.com ≠ flytap.com",
        ],
        explanation="Angler Phishing nas redes sociais. Atacantes monitorizam reclamações e respondem com contas falsas de suporte. Verifica sempre o handle oficial antes de partilhar dados.",
        difficulty="medium"
    ),
]

_WHALING_SCENARIOS = [
    WhalingScenario(
        id="w001",
        target_role="Chief Financial Officer (CFO)",
        sender_name="Dr. António Rodrigues",
        sender_role="Presidente do Conselho de Administração",
        subject="URGENTE: Transferência Confidencial — Aquisição Estratégica",
        email_body="""Dr. Miguel Santos,

Conforme discutimos ontem na reunião do CA, a aquisição da Innovatech avança amanhã.

O advogado da contraparte (Francisco Lopes, da Lopes & Associados) confirmou que a transferência de 847.000€ deve ser feita HOJE até às 17h para garantir a prioridade contratual.

IBANO de destino: PT50000201231234567890154
Referência: ACQ-2024-IT-CONF

Esta operação é ESTRITAMENTE CONFIDENCIAL. Não consulte o departamento financeiro interno nem o compliance até à conclusão — risco de fuga de informação para a concorrência.

Responda apenas para este email. Não me ligue pois estou em reunião até às 18h.

Com os melhores cumprimentos,
Dr. António Rodrigues
Presidente do CA""",
        urgency_level="Crítica",
        is_phishing=True,
        red_flags=[
            "Pedido de transferência urgente sem processo normal de aprovação",
            "Instrução explícita de NÃO consultar compliance ou departamento financeiro",
            "Prazo artificial para pressionar a tomada de decisão imediata",
            "Pedido para comunicar apenas por email — evita verificação vocal",
            "Valor elevado (847.000€) transferido para conta externa desconhecida",
            "Email pode vir de domínio similar: antonio.rodrigues@empresa-corp.com vs @empresa.com",
        ],
        explanation="Whaling / BEC (Business Email Compromise). Ataque altamente sofisticado direcionado ao CFO. A instrução de confidencialidade é para isolar a vítima. Qualquer transferência urgente deve ser verificada por chamada telefónica direta.",
        difficulty="hard"
    ),
]

# ─── Endpoints ───────────────────────────────────────────────────────────────

@router.get("/vishing", response_model=list[VishingScenario])
def get_vishing_scenarios(difficulty: Optional[str] = None):
    if difficulty:
        return [s for s in _VISHING_SCENARIOS if s.difficulty == difficulty]
    return _VISHING_SCENARIOS

@router.get("/vishing/{scenario_id}", response_model=VishingScenario)
def get_vishing_scenario(scenario_id: str):
    for s in _VISHING_SCENARIOS:
        if s.id == scenario_id:
            return s
    raise HTTPException(status_code=404, detail="Cenário não encontrado")

@router.get("/vishing/random", response_model=VishingScenario)
def get_random_vishing(difficulty: Optional[str] = None):
    pool = _VISHING_SCENARIOS
    if difficulty:
        pool = [s for s in pool if s.difficulty == difficulty]
    if not pool:
        raise HTTPException(status_code=404, detail="Sem cenários disponíveis")
    return random.choice(pool)

@router.get("/search-phishing", response_model=list[SearchPhishingScenario])
def get_search_phishing_scenarios():
    return _SEARCH_PHISHING_SCENARIOS

@router.get("/search-phishing/random", response_model=SearchPhishingScenario)
def get_random_search_phishing():
    return random.choice(_SEARCH_PHISHING_SCENARIOS)

@router.get("/quishing", response_model=list[QuishingScenario])
def get_quishing_scenarios():
    return _QUISHING_SCENARIOS

@router.get("/quishing/random", response_model=QuishingScenario)
def get_random_quishing():
    return random.choice(_QUISHING_SCENARIOS)

@router.get("/pharming", response_model=list[PharmingScenario])
def get_pharming_scenarios():
    return _PHARMING_SCENARIOS

@router.get("/pharming/random", response_model=PharmingScenario)
def get_random_pharming():
    return random.choice(_PHARMING_SCENARIOS)

@router.get("/angler", response_model=list[AnglerScenario])
def get_angler_scenarios():
    return _ANGLER_SCENARIOS

@router.get("/angler/random", response_model=AnglerScenario)
def get_random_angler():
    return random.choice(_ANGLER_SCENARIOS)

@router.get("/whaling", response_model=list[WhalingScenario])
def get_whaling_scenarios():
    return _WHALING_SCENARIOS

@router.get("/whaling/random", response_model=WhalingScenario)
def get_random_whaling():
    return random.choice(_WHALING_SCENARIOS)

@router.post("/answer", response_model=SimResult)
def submit_sim_answer(body: SimUserAnswer):
    """
    Avalia a resposta do utilizador para qualquer tipo de simulação avançada.
    """
    # Encontrar o cenário correto
    scenario_map = {
        "vishing": _VISHING_SCENARIOS,
        "search": _SEARCH_PHISHING_SCENARIOS,
        "quishing": _QUISHING_SCENARIOS,
        "pharming": _PHARMING_SCENARIOS,
        "angler": _ANGLER_SCENARIOS,
        "whaling": _WHALING_SCENARIOS,
    }

    pool = scenario_map.get(body.sim_type, [])
    scenario = next((s for s in pool if s.id == body.sim_id), None)

    if not scenario:
        raise HTTPException(status_code=404, detail="Cenário não encontrado")

    correct_answer = scenario.is_phishing
    is_correct = body.user_answer == correct_answer

    # XP baseado em dificuldade
    xp_map = {"easy": 10, "medium": 20, "hard": 35}
    base_xp = xp_map.get(scenario.difficulty, 15)
    xp_earned = base_xp if is_correct else 0

    # Bónus por rapidez (opcional)
    if is_correct and body.time_spent_seconds and body.time_spent_seconds < 30:
        xp_earned += 5

    return SimResult(
        correct=is_correct,
        xp_earned=xp_earned,
        explanation=scenario.explanation,
        correct_answer=correct_answer,
    )