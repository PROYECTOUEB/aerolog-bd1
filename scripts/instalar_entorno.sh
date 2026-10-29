#!/usr/bin/env bash
# Instala el entorno de desarrollo de AeroLog en macOS o Linux (ejecutar desde la raíz del proyecto).
set -e
echo "== AeroLog: instalación del entorno =="
PY=$(command -v python3 || command -v python || true)
if [ -z "$PY" ]; then echo "Instale Python 3.10 o superior (https://www.python.org/downloads/) y vuelva a ejecutar."; exit 1; fi
[ -d .venv ] || "$PY" -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
[ -f .env ] || { cp .env.example .env; echo "Se creó .env: escriba la contraseña de aerolog_app."; }
if command -v code >/dev/null; then
  for ext in ms-python.python ms-python.vscode-pylance ms-python.debugpy mtxr.sqltools mtxr.sqltools-driver-pg; do
    code --install-extension "$ext" --force >/dev/null
  done
  echo "Extensiones de VS Code instaladas."
fi
.venv/bin/python -c "import flask, psycopg; print('Flask', flask.__version__, '| psycopg', psycopg.__version__)"
echo "Listo. Ejecute la aplicación con F5 (AeroLog: ejecutar aplicación) o: .venv/bin/python run.py"
