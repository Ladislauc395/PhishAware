# PhishAware — Guia de Setup

## Estrutura do Projeto

```
phishaware/
├── backend/                  ← FastAPI (Python)
│   ├── app/
│   │   ├── main.py
│   │   ├── models.py
│   │   ├── data.py           ← 10 questões baseadas no Google Phishing Quiz
│   │   └── routers/
│   │       ├── quiz.py
│   │       ├── simulations.py
│   │       ├── chat.py       ← Gemini AI
│   │       └── stats.py
│   ├── requirements.txt
│   └── start.sh
│
└── flutter_fixes/            ← Ficheiros Flutter corrigidos
    ├── pubspec.yaml          ← SUBSTITUI o teu pubspec.yaml
    ├── main.dart             ← lib/main.dart
    ├── app_models.dart       ← lib/models/app_models.dart
    ├── api_service.dart      ← lib/services/api_service.dart
    ├── main_shell.dart       ← lib/screen/main_shell.dart
    ├── login_screen.dart     ← lib/screen/login_screen.dart
    ├── dashboard_screen.dart ← lib/screen/dashboard_screen.dart
    ├── simulation_screen.dart← lib/screen/simulation_screen.dart
    ├── quiz_screen.dart      ← lib/screen/quiz_screen.dart
    ├── assistent_screen.dart ← lib/screen/assistent_screen.dart
    └── tips_screen.dart      ← (mantém o existente, sem alterações)
```

---

## 1. Backend (FastAPI)

### Instalar e iniciar:
```bash
cd backend
pip install -r requirements.txt

# Cria ficheiro .env com a tua chave Gemini:
echo "GEMINI_API_KEY=AIzaSy_a_tua_chave_aqui" > .env

# Iniciar o servidor:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

O backend fica disponível em: http://localhost:8000
Documentação automática: http://localhost:8000/docs

---

## 2. Flutter — O que substituir

### Estrutura de pastas que precisas de ter:
```
lib/
├── main.dart                 ← substituir
├── models/
│   └── app_models.dart       ← substituir (resolve conflito Simulation)
├── services/
│   └── api_service.dart      ← NOVO FICHEIRO (criar pasta services/)
└── screen/
    ├── main_shell.dart        ← substituir
    ├── login_screen.dart      ← substituir (sem imagem PNG)
    ├── dashboard_screen.dart  ← substituir (gráfico bonito)
    ├── simulation_screen.dart ← substituir (usa PhishSimulation)
    ├── quiz_screen.dart       ← substituir (conectado ao backend)
    └── assistent_screen.dart  ← substituir (chat funcional)
```

### Instalar dependências Flutter:
```bash
flutter pub get
```

---

## 3. O que foi corrigido

| Problema | Solução |
|----------|---------|
| Imagem PNG 404 | Removida — logo usa emoji 🛡️ em vez de asset |
| Conflito `Simulation` | Renomeado para `PhishSimulation` em todo o projeto |
| Linha branca no BottomNav | BottomNav reconstruído sem `BottomAppBar` problemático |
| Dashboard sem gráfico | Gráfico de arco animado com glow e cores dinâmicas |
| Chatbot sem resposta | Conectado ao backend FastAPI com Gemini real |
| Simulações estáticas | Carregadas dinamicamente da API |
| XP não guardado | Backend com endpoint `/stats/add-xp` |
| `gemini-3-flash-preview` | Substituído por `gemini-1.5-flash` |

---

## 4. Como o chat IA funciona agora

```
Flutter App → POST /chat/message → FastAPI → Google Gemini API → resposta
```

A chave Gemini fica APENAS no servidor (`.env`), não no código Flutter.
Muito mais seguro do que ter a chave hardcoded no app.
