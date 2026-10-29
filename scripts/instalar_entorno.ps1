# Instala el entorno de desarrollo de AeroLog en Windows (ejecutar desde la raíz del proyecto).
$ErrorActionPreference = "Stop"
Write-Host "== AeroLog: instalación del entorno ==" -ForegroundColor Cyan

$py = Get-Command py -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
if (-not $py) {
  Write-Host "No se encontró Python. Instalándolo con winget..." -ForegroundColor Yellow
  winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
  Write-Host "Cierre y vuelva a abrir Visual Studio Code y ejecute de nuevo este script." -ForegroundColor Yellow
  exit 1
}
if (-not (Test-Path ".venv")) {
  Write-Host "Creando entorno virtual .venv"
  if ($py.Name -eq "py.exe") { py -3 -m venv .venv } else { python -m venv .venv }
}
& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt

if (-not (Test-Path ".env")) { Copy-Item .env.example .env; Write-Host "Se creó .env: escriba la contraseña de aerolog_app." -ForegroundColor Yellow }

if (Get-Command code -ErrorAction SilentlyContinue) {
  foreach ($ext in @("ms-python.python","ms-python.vscode-pylance","ms-python.debugpy","mtxr.sqltools","mtxr.sqltools-driver-pg")) {
    code --install-extension $ext --force | Out-Null
  }
  Write-Host "Extensiones de VS Code instaladas."
}
& .\.venv\Scripts\python.exe -c "import flask, psycopg; print('Flask', flask.__version__, '| psycopg', psycopg.__version__)"
Write-Host "Listo. Ejecute la aplicación con F5 (AeroLog: ejecutar aplicación) o: .venv\Scripts\python run.py" -ForegroundColor Green
