"""Capa de acceso a datos de AeroLog.

Toda la aplicación accede a PostgreSQL a través de tres funciones:
  consultar(sql, params) -> lista de diccionarios
  uno(sql, params)       -> un diccionario o None
  tabla(sql)             -> (columnas, filas) para mostrar resultados tabulares

El controlador por defecto es psycopg 3. Como alternativa para entornos de prueba
sin psycopg, el controlador 'psql' ejecuta las mismas consultas mediante el cliente
de línea de comandos de PostgreSQL.
"""
import csv
import io
import json
import os
import subprocess

from flask import current_app


class ErrorBaseDatos(Exception):
    """Error al conectarse o al ejecutar una consulta."""


def _cfg():
    return current_app.config


# ---------------------------------------------------------------- psycopg 3
def _conectar_psycopg():
    import psycopg
    from psycopg.rows import dict_row  # noqa: F401  (se usa en consultar)
    c = _cfg()
    try:
        return psycopg.connect(
            host=c['DB_HOST'], port=c['DB_PORT'], dbname=c['DB_NAME'],
            user=c['DB_USER'], password=c['DB_PASSWORD'], connect_timeout=5,
            options=f"-c statement_timeout={c['DB_STATEMENT_TIMEOUT']} -c default_transaction_read_only=on",
            application_name='aerolog-web',
        )
    except psycopg.Error as e:
        raise ErrorBaseDatos(f'No fue posible conectarse a la base de datos: {e}') from e


def _psycopg_consultar(sql, params):
    import psycopg
    from psycopg.rows import dict_row
    with _conectar_psycopg() as conn:
        try:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(sql, params)
                return cur.fetchall()
        except psycopg.Error as e:
            raise ErrorBaseDatos(str(e).strip()) from e


def _psycopg_tabla(sql):
    import psycopg
    with _conectar_psycopg() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute(sql)
                cols = [d.name for d in cur.description]
                return cols, [list(r) for r in cur.fetchall()]
        except psycopg.Error as e:
            raise ErrorBaseDatos(str(e).strip()) from e


# ---------------------------------------------------------------- psql (pruebas)
def _literal(v):
    if v is None:
        return 'NULL'
    if isinstance(v, bool):
        return 'TRUE' if v else 'FALSE'
    if isinstance(v, (int, float)):
        return repr(v)
    return "'" + str(v).replace("'", "''") + "'"


def _psql(sql, extra_args):
    c = _cfg()
    env = dict(os.environ, PGPASSWORD=c['DB_PASSWORD'], PGCONNECT_TIMEOUT='5',
               PGOPTIONS=f"-c statement_timeout={c['DB_STATEMENT_TIMEOUT']} -c default_transaction_read_only=on")
    cmd = ['psql', '-h', str(c['DB_HOST']), '-p', str(c['DB_PORT']), '-U', c['DB_USER'], '-d', c['DB_NAME'],
           '-X', '-q', '-v', 'ON_ERROR_STOP=1', *extra_args, '-c', sql]
    r = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if r.returncode != 0:
        raise ErrorBaseDatos(r.stderr.strip() or 'Error al ejecutar la consulta')
    return r.stdout


def _psql_consultar(sql, params):
    if params:
        sql = sql % {k: _literal(v) for k, v in params.items()}
    envuelta = f"SELECT COALESCE(json_agg(t), '[]'::json) FROM ({sql.strip().rstrip(';')}) AS t"
    return json.loads(_psql(envuelta, ['-A', '-t']))


def _psql_tabla(sql):
    salida = _psql(sql.strip().rstrip(';'), ['--csv'])
    filas = list(csv.reader(io.StringIO(salida)))
    if not filas:
        return [], []
    return filas[0], [[None if v == '' else v for v in f] for f in filas[1:]]


# ---------------------------------------------------------------- API pública
def consultar(sql, params=None):
    if _cfg()['DB_DRIVER'] == 'psql':
        return _psql_consultar(sql, params)
    return _psycopg_consultar(sql, params)


def uno(sql, params=None):
    filas = consultar(sql, params)
    return filas[0] if filas else None


def tabla(sql):
    if _cfg()['DB_DRIVER'] == 'psql':
        return _psql_tabla(sql)
    return _psycopg_tabla(sql)
