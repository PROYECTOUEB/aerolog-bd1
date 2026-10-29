"""Configuración de la aplicación a partir de variables de entorno (archivo .env)."""
import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
    DB_PORT = int(os.getenv('DB_PORT', '5432'))
    DB_NAME = os.getenv('DB_NAME', 'aerolog')
    DB_USER = os.getenv('DB_USER', 'aerolog_app')
    DB_PASSWORD = os.getenv('DB_PASSWORD', '')
    # Tiempo máximo de ejecución de una consulta, en milisegundos
    DB_STATEMENT_TIMEOUT = int(os.getenv('DB_STATEMENT_TIMEOUT', '5000'))
    # Controlador: 'psycopg' (producción) o 'psql' (pruebas sin psycopg instalado)
    DB_DRIVER = os.getenv('DB_DRIVER', 'psycopg')
    APP_HOST = os.getenv('APP_HOST', '127.0.0.1')
    APP_PORT = int(os.getenv('APP_PORT', '5000'))
    DEBUG = os.getenv('FLASK_DEBUG', '0') == '1'
