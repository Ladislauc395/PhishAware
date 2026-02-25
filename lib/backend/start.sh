#!/bin/bash
# Instala dependências e inicia o servidor
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
