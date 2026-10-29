"""Endpoints de la API REST de AeroLog (solo lectura)."""
import json
import os

from flask import Blueprint, abort, jsonify, request

from .db import consultar, tabla, uno

api = Blueprint('api', __name__)

with open(os.path.join(os.path.dirname(__file__), 'consultas.json'), encoding='utf-8') as _f:
    _CONSULTAS = json.load(_f)

# Fragmentos reutilizables ------------------------------------------------------
DURACION = '(v.horometro_final - v.horometro_inicial)'
NOMBRE = "p.nombres || ' ' || p.apellidos"
SIN_TILDES = "translate(lower({}), 'áéíóúüñ', 'aeiouun')"


def _sin_tildes(texto):
    return texto.lower().translate(str.maketrans('áéíóúüñ', 'aeiouun'))


def _arg(nombre, permitidos=None):
    v = request.args.get(nombre, '').strip()
    if not v:
        return None
    if permitidos and v not in permitidos:
        abort(400, description=f'Valor no permitido para {nombre}')
    return v


# Estado de la conexión -----------------------------------------------------------
@api.get('/estado')
def estado():
    info = uno("""
        SELECT version() AS version, current_database() AS base_datos, current_user AS usuario,
               inet_server_addr()::text AS servidor, inet_server_port() AS puerto,
               to_char(now(), 'YYYY-MM-DD HH24:MI:SS') AS fecha_servidor,
               current_setting('default_transaction_read_only') AS solo_lectura
    """)
    conteos = consultar("""
        SELECT relname AS tabla, n_live_tup::int AS registros
        FROM pg_stat_user_tables ORDER BY relname
    """)
    exactos = uno("""
        SELECT (SELECT count(*) FROM persona) AS persona, (SELECT count(*) FROM aeronave) AS aeronave,
               (SELECT count(*) FROM vuelo) AS vuelo, (SELECT count(*) FROM orden_trabajo) AS orden_trabajo,
               (SELECT count(*) FROM evaluacion_maniobra) AS evaluacion_maniobra,
               (SELECT count(*) FROM matricula) AS matricula
    """)
    return jsonify(conexion='ok', servidor=info, tablas=len(conteos), conteos=exactos)


# Panel de control ----------------------------------------------------------------
@api.get('/panel')
def panel():
    kpi = uno(f"""
        SELECT
          (SELECT count(*) FROM vuelo WHERE estado = 'REALIZADO') AS vuelos_realizados,
          (SELECT COALESCE(round(sum(horometro_final - horometro_inicial), 1), 0) FROM vuelo WHERE estado = 'REALIZADO') AS horas_voladas,
          (SELECT count(*) FROM vuelo WHERE estado = 'PROGRAMADO') AS vuelos_programados,
          (SELECT count(DISTINCT id_estudiante) FROM matricula WHERE estado = 'ACTIVA') AS estudiantes_activos,
          (SELECT count(*) FROM instructor) AS instructores,
          (SELECT count(*) FROM aeronave) AS aeronaves,
          (SELECT count(*) FROM aeronave WHERE estado = 'DISPONIBLE') AS aeronaves_disponibles,
          (SELECT count(*) FROM orden_trabajo WHERE fecha_cierre IS NULL) AS ordenes_abiertas
    """)
    alertas = consultar(f"""
        SELECT 'Certificado médico' AS tipo, {NOMBRE} AS sujeto,
               CASE WHEN c.fecha_vencimiento < CURRENT_DATE THEN 'Vencido' ELSE 'Vence pronto' END AS detalle,
               c.fecha_vencimiento AS fecha, CASE WHEN c.fecha_vencimiento < CURRENT_DATE THEN 'alta' ELSE 'media' END AS nivel,
               '#/estudiantes/' || p.id_persona AS enlace
        FROM certificado_medico c JOIN persona p ON p.id_persona = c.id_estudiante
        WHERE c.fecha_vencimiento < CURRENT_DATE + 30
          AND c.id_estudiante IN (SELECT id_estudiante FROM matricula WHERE estado = 'ACTIVA')
        UNION ALL
        SELECT 'Aeronave no apta', a.matricula,
               CASE WHEN a.estado <> 'DISPONIBLE' THEN replace(a.estado, '_', ' ')
                    WHEN ca.matricula IS NULL THEN 'Sin certificado de aeronavegabilidad'
                    ELSE 'Certificado de aeronavegabilidad vencido' END,
               ca.fecha_vencimiento, 'alta', '#/flota/' || a.matricula
        FROM aeronave a LEFT JOIN cert_aeronavegabilidad ca ON ca.matricula = a.matricula
        WHERE a.estado <> 'DISPONIBLE' OR ca.matricula IS NULL OR ca.fecha_vencimiento < CURRENT_DATE
        UNION ALL
        SELECT 'Licencia de instructor', {NOMBRE},
               CASE WHEN i.fecha_venc_licencia < CURRENT_DATE THEN 'Vencida' ELSE 'Vence en menos de 60 días' END,
               i.fecha_venc_licencia, CASE WHEN i.fecha_venc_licencia < CURRENT_DATE THEN 'alta' ELSE 'media' END,
               '#/instructores'
        FROM instructor i JOIN persona p ON p.id_persona = i.id_persona
        WHERE i.fecha_venc_licencia < CURRENT_DATE + 60
        UNION ALL
        SELECT 'Orden de trabajo abierta', o.matricula, replace(o.tipo_orden, '_', ' '), o.fecha_apertura, 'baja',
               '#/mantenimiento/' || o.id_orden
        FROM orden_trabajo o WHERE o.fecha_cierre IS NULL
        ORDER BY 5, 4
    """)
    horas_aeronave = consultar(f"""
        SELECT a.matricula, m.nombre AS modelo, COALESCE(round(sum({DURACION}), 1), 0) AS horas
        FROM aeronave a JOIN modelo_aeronave m ON m.id_modelo = a.id_modelo
        LEFT JOIN vuelo v ON v.matricula = a.matricula AND v.estado = 'REALIZADO'
        GROUP BY a.matricula, m.nombre ORDER BY horas DESC
    """)
    por_tipo = consultar(f"""
        SELECT v.tipo_vuelo AS tipo, count(*) AS vuelos, round(avg({DURACION}), 2) AS duracion_promedio
        FROM vuelo v WHERE v.estado = 'REALIZADO' GROUP BY v.tipo_vuelo ORDER BY vuelos DESC
    """)
    por_mes = consultar("""
        SELECT to_char(fecha_vuelo, 'YYYY-MM') AS mes, count(*) FILTER (WHERE estado = 'REALIZADO') AS realizados,
               count(*) FILTER (WHERE estado = 'CANCELADO') AS cancelados
        FROM vuelo GROUP BY 1 ORDER BY 1
    """)
    proximos = consultar(f"""
        SELECT v.id_vuelo, v.fecha_vuelo, v.hora_salida, v.tipo_vuelo, v.matricula,
               {NOMBRE} AS estudiante, v.aerodromo_origen, v.aerodromo_destino
        FROM vuelo v JOIN persona p ON p.id_persona = v.id_estudiante
        WHERE v.estado = 'PROGRAMADO' ORDER BY v.fecha_vuelo, v.hora_salida LIMIT 8
    """)
    return jsonify(kpi=kpi, alertas=alertas, horas_aeronave=horas_aeronave, por_tipo=por_tipo,
                   por_mes=por_mes, proximos=proximos)


# Estudiantes -------------------------------------------------------------------------
@api.get('/estudiantes')
def estudiantes():
    q = _arg('q')
    filas = consultar(f"""
        SELECT e.id_persona, e.codigo_estudiante, p.nombres, p.apellidos, p.correo,
               (SELECT string_agg(pr.nombre, ', ' ORDER BY pr.nombre) FROM matricula m
                  JOIN programa pr ON pr.id_programa = m.id_programa
                 WHERE m.id_estudiante = e.id_persona AND m.estado = 'ACTIVA') AS programa_activo,
               (SELECT count(*) FROM vuelo v WHERE v.id_estudiante = e.id_persona AND v.estado = 'REALIZADO') AS vuelos,
               (SELECT COALESCE(round(sum({DURACION}), 1), 0) FROM vuelo v
                 WHERE v.id_estudiante = e.id_persona AND v.estado = 'REALIZADO') AS horas,
               c.fecha_vencimiento AS venc_certificado,
               CASE WHEN c.id_certificado IS NULL THEN 'SIN REGISTRO'
                    WHEN c.fecha_vencimiento < CURRENT_DATE THEN 'VENCIDO' ELSE 'VIGENTE' END AS estado_certificado
        FROM estudiante e JOIN persona p ON p.id_persona = e.id_persona
        LEFT JOIN certificado_medico c ON c.id_estudiante = e.id_persona
        WHERE %(patron)s::text IS NULL
           OR {SIN_TILDES.format('e.codigo_estudiante')} LIKE %(patron)s
           OR {SIN_TILDES.format("p.nombres || ' ' || p.apellidos")} LIKE %(patron)s
           OR p.numero_documento LIKE %(patron)s
        ORDER BY e.codigo_estudiante
    """, {'patron': f'%{_sin_tildes(q)}%' if q else None})
    return jsonify(filas)


@api.get('/estudiantes/<int:id_persona>')
def estudiante(id_persona):
    datos = uno("""
        SELECT p.*, e.codigo_estudiante, e.fecha_ingreso,
               date_part('year', age(p.fecha_nacimiento))::int AS edad,
               EXISTS (SELECT 1 FROM instructor i WHERE i.id_persona = p.id_persona) AS es_instructor,
               EXISTS (SELECT 1 FROM tecnico t WHERE t.id_persona = p.id_persona) AS es_tecnico
        FROM estudiante e JOIN persona p ON p.id_persona = e.id_persona WHERE e.id_persona = %(id)s
    """, {'id': id_persona})
    if not datos:
        abort(404)
    p = {'id': id_persona}
    certificado = uno("""
        SELECT numero_certificado, clase, fecha_expedicion, fecha_vencimiento,
               CASE WHEN fecha_vencimiento < CURRENT_DATE THEN 'VENCIDO' ELSE 'VIGENTE' END AS estado
        FROM certificado_medico WHERE id_estudiante = %(id)s
    """, p)
    matriculas = consultar(f"""
        SELECT m.id_matricula, pr.nombre AS programa, m.fecha_matricula, m.estado, pr.valor,
               pr.horas_minimas_vuelo,
               (SELECT COALESCE(sum(valor), 0) FROM pago pg WHERE pg.id_matricula = m.id_matricula) AS total_pagado,
               (SELECT COALESCE(round(sum({DURACION}), 1), 0) FROM vuelo v
                 WHERE v.id_estudiante = m.id_estudiante AND v.estado = 'REALIZADO') AS horas
        FROM matricula m JOIN programa pr ON pr.id_programa = m.id_programa
        WHERE m.id_estudiante = %(id)s ORDER BY m.fecha_matricula
    """, p)
    calificaciones = consultar("""
        SELECT cu.nombre AS curso, ca.nota_final, ca.fecha_calificacion,
               CASE WHEN ca.nota_final >= 3.0 THEN 'APROBADO' ELSE 'REPROBADO' END AS estado
        FROM calificacion ca JOIN curso cu ON cu.id_curso = ca.id_curso
        WHERE ca.id_estudiante = %(id)s ORDER BY cu.nombre
    """, p)
    bitacora = consultar(f"""
        SELECT v.id_vuelo, v.fecha_vuelo, v.hora_salida, v.tipo_vuelo, v.estado, v.matricula, mo.nombre AS modelo,
               v.aerodromo_origen, v.aerodromo_destino, {DURACION} AS duracion,
               pi.nombres || ' ' || pi.apellidos AS instructor, iv.resultado
        FROM vuelo v JOIN aeronave a ON a.matricula = v.matricula
        JOIN modelo_aeronave mo ON mo.id_modelo = a.id_modelo
        LEFT JOIN persona pi ON pi.id_persona = v.id_instructor
        LEFT JOIN informe_vuelo iv ON iv.id_vuelo = v.id_vuelo
        WHERE v.id_estudiante = %(id)s ORDER BY v.fecha_vuelo DESC, v.hora_salida DESC
    """, p)
    resumen = consultar(f"""
        SELECT v.tipo_vuelo AS tipo, count(*) AS vuelos, round(sum({DURACION}), 1) AS horas
        FROM vuelo v WHERE v.id_estudiante = %(id)s AND v.estado = 'REALIZADO'
        GROUP BY v.tipo_vuelo ORDER BY horas DESC
    """, p)
    return jsonify(datos=datos, certificado=certificado, matriculas=matriculas,
                   calificaciones=calificaciones, bitacora=bitacora, resumen=resumen)


# Instructores ----------------------------------------------------------------------
@api.get('/instructores')
def instructores():
    return jsonify(consultar(f"""
        SELECT i.id_persona, {NOMBRE} AS nombre, p.correo, i.numero_licencia, i.fecha_venc_licencia,
               CASE WHEN i.fecha_venc_licencia < CURRENT_DATE THEN 'VENCIDA'
                    WHEN i.fecha_venc_licencia < CURRENT_DATE + 60 THEN 'POR VENCER' ELSE 'VIGENTE' END AS estado_licencia,
               (SELECT string_agg(m.nombre, ', ' ORDER BY m.nombre) FROM habilitacion h
                  JOIN modelo_aeronave m ON m.id_modelo = h.id_modelo WHERE h.id_instructor = i.id_persona) AS habilitaciones,
               (SELECT count(*) FROM vuelo v WHERE v.id_instructor = i.id_persona AND v.estado = 'REALIZADO') AS vuelos,
               (SELECT COALESCE(round(sum({DURACION}), 1), 0) FROM vuelo v
                 WHERE v.id_instructor = i.id_persona AND v.estado = 'REALIZADO') AS horas,
               EXISTS (SELECT 1 FROM estudiante e WHERE e.id_persona = i.id_persona) AS tambien_estudiante,
               EXISTS (SELECT 1 FROM tecnico t WHERE t.id_persona = i.id_persona) AS tambien_tecnico
        FROM instructor i JOIN persona p ON p.id_persona = i.id_persona ORDER BY nombre
    """))


# Flota ----------------------------------------------------------------------------
@api.get('/aeronaves')
def aeronaves():
    return jsonify(consultar(f"""
        SELECT a.matricula, m.nombre AS modelo, f.nombre AS fabricante, m.numero_motores, a.anio_fabricacion,
               a.horas_totales, a.estado, ca.numero_certificado, ca.fecha_vencimiento AS venc_certificado,
               CASE WHEN ca.matricula IS NULL THEN 'SIN REGISTRO'
                    WHEN ca.fecha_vencimiento < CURRENT_DATE THEN 'VENCIDO' ELSE 'VIGENTE' END AS estado_certificado,
               (SELECT count(*) FROM vuelo v WHERE v.matricula = a.matricula AND v.estado = 'REALIZADO') AS vuelos,
               (SELECT COALESCE(round(sum({DURACION}), 1), 0) FROM vuelo v
                 WHERE v.matricula = a.matricula AND v.estado = 'REALIZADO') AS horas_voladas,
               (SELECT max(fecha_apertura) FROM orden_trabajo o WHERE o.matricula = a.matricula) AS ultimo_mantenimiento
        FROM aeronave a JOIN modelo_aeronave m ON m.id_modelo = a.id_modelo
        JOIN fabricante f ON f.id_fabricante = m.id_fabricante
        LEFT JOIN cert_aeronavegabilidad ca ON ca.matricula = a.matricula
        ORDER BY a.matricula
    """))


@api.get('/aeronaves/<matricula>')
def aeronave(matricula):
    p = {'m': matricula}
    datos = uno("""
        SELECT a.*, m.nombre AS modelo, m.numero_motores, m.capacidad_asientos, m.velocidad_crucero_kt,
               f.nombre AS fabricante, f.pais_origen, ca.numero_certificado, ca.fecha_expedicion,
               ca.fecha_vencimiento AS venc_certificado
        FROM aeronave a JOIN modelo_aeronave m ON m.id_modelo = a.id_modelo
        JOIN fabricante f ON f.id_fabricante = m.id_fabricante
        LEFT JOIN cert_aeronavegabilidad ca ON ca.matricula = a.matricula
        WHERE a.matricula = %(m)s
    """, p)
    if not datos:
        abort(404)
    vuelos = consultar(f"""
        SELECT v.id_vuelo, v.fecha_vuelo, v.hora_salida, v.tipo_vuelo, v.estado, {NOMBRE} AS estudiante,
               v.aerodromo_origen, v.aerodromo_destino, {DURACION} AS duracion
        FROM vuelo v JOIN persona p ON p.id_persona = v.id_estudiante
        WHERE v.matricula = %(m)s ORDER BY v.fecha_vuelo DESC LIMIT 25
    """, p)
    ordenes = consultar("""
        SELECT o.id_orden, o.tipo_orden, o.fecha_apertura, o.fecha_cierre, o.horas_aeronave,
               (SELECT COALESCE(sum(d.cantidad * r.costo_unitario), 0) FROM detalle_repuesto d
                  JOIN repuesto r ON r.numero_parte = d.numero_parte WHERE d.id_orden = o.id_orden) AS costo_repuestos,
               (SELECT count(*) FROM asignacion_tecnico t WHERE t.id_orden = o.id_orden) AS tecnicos
        FROM orden_trabajo o WHERE o.matricula = %(m)s ORDER BY o.fecha_apertura DESC
    """, p)
    habilitados = consultar(f"""
        SELECT {NOMBRE} AS instructor, h.fecha_habilitacion
        FROM aeronave a JOIN habilitacion h ON h.id_modelo = a.id_modelo
        JOIN persona p ON p.id_persona = h.id_instructor WHERE a.matricula = %(m)s ORDER BY 1
    """, p)
    return jsonify(datos=datos, vuelos=vuelos, ordenes=ordenes, habilitados=habilitados)


# Vuelos --------------------------------------------------------------------------
TIPOS = {'LOCAL', 'NAVEGACION', 'SOLO', 'EXAMEN'}
ESTADOS = {'PROGRAMADO', 'REALIZADO', 'CANCELADO'}


@api.get('/vuelos')
def vuelos():
    params = {
        'estado': _arg('estado', ESTADOS), 'tipo': _arg('tipo', TIPOS), 'matricula': _arg('matricula'),
        'desde': _arg('desde'), 'hasta': _arg('hasta'),
    }
    return jsonify(consultar(f"""
        SELECT v.id_vuelo, v.fecha_vuelo, v.hora_salida, v.tipo_vuelo, v.estado, v.matricula,
               v.aerodromo_origen, v.aerodromo_destino, {DURACION} AS duracion,
               v.id_estudiante, {NOMBRE} AS estudiante, pi.nombres || ' ' || pi.apellidos AS instructor
        FROM vuelo v JOIN persona p ON p.id_persona = v.id_estudiante
        LEFT JOIN persona pi ON pi.id_persona = v.id_instructor
        WHERE (%(estado)s::text IS NULL OR v.estado = %(estado)s)
          AND (%(tipo)s::text IS NULL OR v.tipo_vuelo = %(tipo)s)
          AND (%(matricula)s::text IS NULL OR v.matricula = %(matricula)s)
          AND (%(desde)s::date IS NULL OR v.fecha_vuelo >= %(desde)s::date)
          AND (%(hasta)s::date IS NULL OR v.fecha_vuelo <= %(hasta)s::date)
        ORDER BY v.fecha_vuelo DESC, v.hora_salida DESC
        LIMIT 500
    """, params))


@api.get('/vuelos/<int:id_vuelo>')
def vuelo(id_vuelo):
    p = {'id': id_vuelo}
    datos = uno(f"""
        SELECT v.*, {DURACION} AS duracion, {NOMBRE} AS estudiante, e.codigo_estudiante,
               pi.nombres || ' ' || pi.apellidos AS instructor, mo.nombre AS modelo,
               ao.nombre AS nombre_origen, ao.ciudad AS ciudad_origen,
               ad.nombre AS nombre_destino, ad.ciudad AS ciudad_destino
        FROM vuelo v JOIN persona p ON p.id_persona = v.id_estudiante
        JOIN estudiante e ON e.id_persona = v.id_estudiante
        LEFT JOIN persona pi ON pi.id_persona = v.id_instructor
        JOIN aeronave a ON a.matricula = v.matricula JOIN modelo_aeronave mo ON mo.id_modelo = a.id_modelo
        JOIN aerodromo ao ON ao.codigo_oaci = v.aerodromo_origen
        JOIN aerodromo ad ON ad.codigo_oaci = v.aerodromo_destino
        WHERE v.id_vuelo = %(id)s
    """, p)
    if not datos:
        abort(404)
    evaluaciones = consultar("""
        SELECT m.nombre AS maniobra, m.fase, e.calificacion, e.observacion
        FROM evaluacion_maniobra e JOIN maniobra m ON m.id_maniobra = e.id_maniobra
        WHERE e.id_vuelo = %(id)s ORDER BY m.id_maniobra
    """, p)
    informe = uno('SELECT fecha_informe, resultado, observaciones FROM informe_vuelo WHERE id_vuelo = %(id)s', p)
    return jsonify(datos=datos, evaluaciones=evaluaciones, informe=informe)


# Mantenimiento -------------------------------------------------------------------
@api.get('/mantenimiento')
def mantenimiento():
    est = _arg('estado', {'abiertas', 'cerradas'})
    return jsonify(consultar("""
        SELECT o.id_orden, o.matricula, o.tipo_orden, o.fecha_apertura, o.fecha_cierre, o.horas_aeronave,
               CASE WHEN o.fecha_cierre IS NULL THEN 'ABIERTA' ELSE 'CERRADA' END AS estado,
               (SELECT COALESCE(sum(d.cantidad * r.costo_unitario), 0) FROM detalle_repuesto d
                  JOIN repuesto r ON r.numero_parte = d.numero_parte WHERE d.id_orden = o.id_orden) AS costo_repuestos,
               (SELECT COALESCE(sum(t.horas_trabajadas), 0) FROM asignacion_tecnico t WHERE t.id_orden = o.id_orden) AS horas_tecnicos,
               (SELECT count(*) FROM asignacion_tecnico t WHERE t.id_orden = o.id_orden) AS tecnicos
        FROM orden_trabajo o
        WHERE %(est)s::text IS NULL OR (%(est)s = 'abiertas' AND o.fecha_cierre IS NULL)
              OR (%(est)s = 'cerradas' AND o.fecha_cierre IS NOT NULL)
        ORDER BY o.fecha_apertura DESC
    """, {'est': est}))


@api.get('/mantenimiento/<int:id_orden>')
def orden(id_orden):
    p = {'id': id_orden}
    datos = uno("""
        SELECT o.*, m.nombre AS modelo, CASE WHEN o.fecha_cierre IS NULL THEN 'ABIERTA' ELSE 'CERRADA' END AS estado
        FROM orden_trabajo o JOIN aeronave a ON a.matricula = o.matricula
        JOIN modelo_aeronave m ON m.id_modelo = a.id_modelo WHERE o.id_orden = %(id)s
    """, p)
    if not datos:
        abort(404)
    tecnicos = consultar(f"""
        SELECT {NOMBRE} AS tecnico, t.especialidad, a.horas_trabajadas, a.labor_realizada
        FROM asignacion_tecnico a JOIN tecnico t ON t.id_persona = a.id_tecnico
        JOIN persona p ON p.id_persona = a.id_tecnico WHERE a.id_orden = %(id)s ORDER BY 1
    """, p)
    repuestos = consultar("""
        SELECT r.numero_parte, r.descripcion, d.cantidad, r.costo_unitario, d.cantidad * r.costo_unitario AS subtotal,
               d.numero_serie, pv.razon_social AS proveedor
        FROM detalle_repuesto d JOIN repuesto r ON r.numero_parte = d.numero_parte
        JOIN proveedor pv ON pv.id_proveedor = r.id_proveedor WHERE d.id_orden = %(id)s ORDER BY r.numero_parte
    """, p)
    return jsonify(datos=datos, tecnicos=tecnicos, repuestos=repuestos)


# Académico -------------------------------------------------------------------------
@api.get('/academico')
def academico():
    programas = consultar("""
        SELECT pr.id_programa, pr.nombre, pr.horas_minimas_vuelo, pr.duracion_meses, pr.valor,
               (SELECT count(*) FROM matricula m WHERE m.id_programa = pr.id_programa AND m.estado = 'ACTIVA') AS activos,
               (SELECT count(*) FROM matricula m WHERE m.id_programa = pr.id_programa) AS matriculas
        FROM programa pr ORDER BY pr.id_programa
    """)
    plan = consultar("""
        SELECT pe.id_programa, pe.etapa, c.id_curso, c.nombre, c.intensidad_horaria,
               (SELECT round(avg(ca.nota_final), 2) FROM calificacion ca WHERE ca.id_curso = c.id_curso) AS promedio,
               (SELECT count(*) FROM calificacion ca WHERE ca.id_curso = c.id_curso AND ca.nota_final < 3) AS reprobados
        FROM plan_estudios pe JOIN curso c ON c.id_curso = pe.id_curso ORDER BY pe.id_programa, pe.etapa, c.nombre
    """)
    for pr in programas:
        pr['cursos'] = [c for c in plan if c['id_programa'] == pr['id_programa']]
    return jsonify(programas)


# Filtros ---------------------------------------------------------------------------
@api.get('/catalogos')
def catalogos():
    return jsonify(
        aeronaves=[r['matricula'] for r in consultar('SELECT matricula FROM aeronave ORDER BY 1')],
        tipos_vuelo=sorted(TIPOS), estados_vuelo=sorted(ESTADOS),
    )


# Consultas de álgebra relacional ------------------------------------------------------
@api.get('/consultas')
def consultas():
    return jsonify([{'n': i + 1, 'categoria': c['cat'], 'pregunta': c['q']} for i, c in enumerate(_CONSULTAS)])


@api.get('/consultas/<int:n>')
def ejecutar_consulta(n):
    if not 1 <= n <= len(_CONSULTAS):
        abort(404)
    c = _CONSULTAS[n - 1]
    columnas, filas = tabla(c['sql'])
    return jsonify(n=n, categoria=c['cat'], pregunta=c['q'], algebra=c['ra'], explicacion=c['exp'],
                   sql=c['sql'], columnas=columnas, filas=filas, total=len(filas))
