"""Aplicación web AeroLog: API REST (Flask) + interfaz web estática."""
import datetime as dt
import decimal

from flask import Flask, jsonify, request, send_from_directory
from flask.json.provider import DefaultJSONProvider

from .config import Config
from .db import ErrorBaseDatos


class JSONAeroLog(DefaultJSONProvider):
    """Serializa los tipos de PostgreSQL (NUMERIC, DATE, TIME) de forma legible."""
    ensure_ascii = False
    sort_keys = False

    @staticmethod
    def default(o):
        if isinstance(o, decimal.Decimal):
            return float(o)
        if isinstance(o, (dt.date, dt.time, dt.datetime)):
            return o.isoformat()
        if isinstance(o, dt.timedelta):
            return o.total_seconds()
        return DefaultJSONProvider.default(o)


def create_app(config=None):
    app = Flask(__name__, static_folder='static', static_url_path='/static')
    app.json_provider_class = JSONAeroLog
    app.json = JSONAeroLog(app)
    app.config.from_object(Config)
    if config:
        app.config.update(config)

    from .api import api
    app.register_blueprint(api, url_prefix='/api')

    @app.get('/')
    def inicio():
        return send_from_directory(app.static_folder, 'index.html')

    @app.errorhandler(ErrorBaseDatos)
    def error_bd(e):
        return jsonify(error='base_de_datos', mensaje=str(e)), 503

    @app.errorhandler(400)
    def solicitud_invalida(e):
        return jsonify(error='solicitud_invalida', mensaje=getattr(e, 'description', 'Solicitud inválida')), 400

    @app.errorhandler(404)
    def no_encontrado(e):
        if request.path.startswith('/api/'):
            return jsonify(error='no_encontrado', mensaje='Recurso no encontrado'), 404
        return send_from_directory(app.static_folder, 'index.html')

    return app
