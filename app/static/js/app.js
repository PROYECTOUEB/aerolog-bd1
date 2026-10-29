/* AeroLog – interfaz web (sin dependencias externas). Consume la API REST en /api. */
'use strict';

const $main = document.getElementById('contenido');

// ------------------------------------------------------------------ utilidades
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const fecha = (v) => { if (!v) return '—'; const [a, m, d] = String(v).slice(0, 10).split('-'); return `${+d} ${MESES[+m - 1]} ${a}`; };
const hora = (v) => (v ? String(v).slice(0, 5) : '—');
const num = (v, dec = 1) => (v === null || v === undefined || v === '' ? '—' : Number(v).toLocaleString('es-CO', { minimumFractionDigits: dec, maximumFractionDigits: dec }));
const cop = (v) => (v === null || v === undefined ? '—' : Number(v).toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }));
const TILDES = { navegacion: 'navegación', avionica: 'aviónica', inspeccion: 'inspección' };
const texto = (v) => (v ? String(v).replace(/_/g, ' ').toLowerCase().replace(/[a-záéíóúñ]+/g, (w) => TILDES[w] || w).replace(/^./, (c) => c.toUpperCase()) : '—');
const TIPO = { LOCAL: 'Local', NAVEGACION: 'Navegación', SOLO: 'Solo', EXAMEN: 'Examen' };

function estado(v) {
  const ok = ['VIGENTE', 'DISPONIBLE', 'REALIZADO', 'ACTIVA', 'APROBADO', 'SATISFACTORIO', 'CERRADA', 'FINALIZADA'];
  const aviso = ['POR VENCER', 'EN_MANTENIMIENTO', 'PROGRAMADO', 'SUSPENDIDA', 'ABIERTA', 'SIN REGISTRO'];
  const mal = ['VENCIDO', 'VENCIDA', 'FUERA_DE_SERVICIO', 'CANCELADO', 'REPROBADO', 'INSATISFACTORIO', 'RETIRADA'];
  const cls = ok.includes(v) ? 'e-ok' : aviso.includes(v) ? 'e-aviso' : mal.includes(v) ? 'e-mal' : 'e-neutro';
  return `<span class="estado ${cls}">${esc(texto(v))}</span>`;
}

async function api(ruta) {
  const r = await fetch(`/api${ruta}`, { headers: { Accept: 'application/json' } });
  let datos = null;
  try { datos = await r.json(); } catch (e) { /* respuesta no JSON */ }
  if (!r.ok) throw new Error((datos && datos.mensaje) || `Error ${r.status} al consultar ${ruta}`);
  return datos;
}

function tablaHTML(columnas, filas, opciones = {}) {
  if (!filas.length) return `<p class="vacio">${esc(opciones.vacio || 'No hay registros para mostrar.')}</p>`;
  const th = columnas.map((c) => `<th class="${c.num ? 'num' : ''}" scope="col">${esc(c.t)}</th>`).join('');
  const tr = filas.map((f) => {
    const enlace = opciones.enlace ? opciones.enlace(f) : null;
    const attrs = enlace ? ` class="fila-enlace" tabindex="0" data-href="${esc(enlace)}"` : '';
    return `<tr${attrs}>${columnas.map((c) => `<td class="${c.num ? 'num' : ''}">${c.f ? c.f(f) : esc(f[c.k] ?? '—')}</td>`).join('')}</tr>`;
  }).join('');
  return `<div class="tabla-envoltura"><table><thead><tr>${th}</tr></thead><tbody>${tr}</tbody></table></div>`;
}

function tiraHTML(v) {
  const ruta = `${esc(v.aerodromo_origen)} → ${esc(v.aerodromo_destino)}`;
  const persona = v.estudiante ? esc(v.estudiante) : '';
  const instr = v.instructor ? `con ${esc(v.instructor)}` : (v.tipo_vuelo === 'SOLO' ? 'sin instructor' : '');
  return `<a class="tira ${esc(v.tipo_vuelo)} ${esc(v.estado)}" href="#/vuelos/${v.id_vuelo}">
    <div><span class="cod">${esc(v.matricula)}</span><span class="min">${esc(v.modelo || TIPO[v.tipo_vuelo])}</span></div>
    <div><span>${fecha(v.fecha_vuelo)}</span><span class="min">${hora(v.hora_salida)} · vuelo ${v.id_vuelo}</span></div>
    <div><span class="ruta">${ruta}</span><span class="min">${persona} ${instr}</span></div>
    <div><span>${TIPO[v.tipo_vuelo] || esc(v.tipo_vuelo)}</span><span class="min">${esc(texto(v.estado))}</span></div>
    <div><span class="cod">${v.duracion != null ? num(v.duracion) : '—'}</span><span class="min">horas</span></div>
  </a>`;
}
const leyenda = '<p class="leyenda" aria-label="Colores por tipo de vuelo"><span class="LOCAL">Local</span><span class="NAVEGACION">Navegación</span><span class="SOLO">Solo</span><span class="EXAMEN">Examen</span></p>';

function barrasHTML(items, etiqueta, valor, sufijo = '') {
  const max = Math.max(...items.map((i) => Number(i[valor]) || 0), 1);
  return `<div class="barras">${items.map((i) => `<div class="barra"><span>${esc(i[etiqueta])}</span>
    <div class="pista"><div class="relleno" style="width:${(100 * (Number(i[valor]) || 0) / max).toFixed(1)}%"></div></div>
    <span class="cifra">${num(i[valor], Number.isInteger(Number(i[valor])) ? 0 : 1)}${sufijo}</span></div>`).join('')}</div>`;
}

const cargando = () => { $main.innerHTML = '<p class="cargando" role="status">Cargando información…</p>'; };
const mostrarError = (e) => {
  $main.innerHTML = `<h1>No fue posible cargar esta sección</h1><div class="error-caja"><p>${esc(e.message)}</p>
    <p>Verifique que la máquina virtual esté encendida, que PostgreSQL esté en ejecución y que los datos del archivo .env sean correctos. Consulte el <a href="#/estado">estado de la conexión</a>.</p></div>`;
};

// ------------------------------------------------------------------ vistas
async function vistaPanel() {
  const d = await api('/panel');
  const k = d.kpi;
  document.title = 'Panel de operaciones – AeroLog';
  $main.innerHTML = `
    <h1>Panel de operaciones</h1>
    <p class="sub">Estado actual de la escuela: vuelos programados, alertas que requieren atención y uso de la flota.</p>
    <section class="instrumentos" aria-label="Indicadores principales">
      <div class="instrumento"><div class="valor">${k.vuelos_realizados}</div><div class="nombre">vuelos realizados</div></div>
      <div class="instrumento"><div class="valor">${num(k.horas_voladas)}</div><div class="nombre">horas de vuelo de instrucción</div></div>
      <div class="instrumento"><div class="valor">${k.estudiantes_activos}</div><div class="nombre">estudiantes con matrícula activa</div></div>
      <div class="instrumento"><div class="valor">${k.aeronaves_disponibles}<small> de ${k.aeronaves}</small></div><div class="nombre">aeronaves disponibles</div></div>
    </section>
    <div class="rejilla dos">
      <section class="bloque">
        <h2>Próximos vuelos programados</h2>
        ${leyenda}
        <div class="tiras">${d.proximos.length ? d.proximos.map(tiraHTML).join('') : '<p class="vacio">No hay vuelos programados.</p>'}</div>
        <p style="margin:14px 0 0"><a href="#/vuelos?estado=PROGRAMADO">Ver toda la programación</a></p>
      </section>
      <section class="bloque">
        <h2>Alertas (${d.alertas.length})</h2>
        ${d.alertas.length ? `<ul class="alertas" id="alertas">${d.alertas.map((a, i) => `<li class="${i >= 7 ? 'oculta' : ''}"><span class="marca-nivel nivel-${a.nivel}" aria-label="Prioridad ${a.nivel}"></span>
          <div><a href="${esc(a.enlace)}">${esc(a.tipo)}: ${esc(a.sujeto)}</a><div class="det">${esc(a.detalle === a.detalle.toUpperCase() ? texto(a.detalle) : a.detalle)}</div></div>
          <span class="det">${fecha(a.fecha)}</span></li>`).join('')}</ul>
          ${d.alertas.length > 7 ? `<button class="btn sec mas" id="ver-alertas" aria-controls="alertas">Mostrar las ${d.alertas.length} alertas</button>` : ''}` : '<p class="vacio">No hay alertas activas.</p>'}
      </section>
    </div>
    <div class="rejilla mitad">
      <section class="bloque"><h2>Horas voladas por aeronave</h2>${barrasHTML(d.horas_aeronave, 'matricula', 'horas', ' h')}</section>
      <section class="bloque"><h2>Vuelos realizados por tipo</h2>
        ${barrasHTML(d.por_tipo.map((t) => ({ ...t, tipo: TIPO[t.tipo] })), 'tipo', 'vuelos')}
        <h3 style="margin-top:22px">Vuelos realizados por mes</h3>
        ${barrasHTML(d.por_mes.map((m) => ({ ...m, mes: fecha(m.mes + '-01').slice(2) })), 'mes', 'realizados')}
      </section>
    </div>`;
  const ver = document.getElementById('ver-alertas');
  if (ver) ver.addEventListener('click', () => { document.querySelectorAll('#alertas li.oculta').forEach((li) => li.classList.remove('oculta')); ver.remove(); });
}

async function vistaVuelos(params) {
  const [cat, filas] = await Promise.all([api('/catalogos'), api('/vuelos?' + params.toString())]);
  document.title = 'Vuelos – AeroLog';
  const sel = (nombre, opciones, etiquetas = {}) => `<select name="${nombre}"><option value="">Todos</option>${opciones.map((o) =>
    `<option value="${esc(o)}" ${params.get(nombre) === o ? 'selected' : ''}>${esc(etiquetas[o] || texto(o))}</option>`).join('')}</select>`;
  const horas = filas.reduce((s, v) => s + (Number(v.duracion) || 0), 0);
  $main.innerHTML = `
    <div class="encabezado"><div><h1>Vuelos</h1><p class="sub">Programación y registro de los vuelos de instrucción.</p></div></div>
    <form class="filtros" id="filtros">
      <label>Estado ${sel('estado', cat.estados_vuelo)}</label>
      <label>Tipo ${sel('tipo', cat.tipos_vuelo, TIPO)}</label>
      <label>Aeronave ${sel('matricula', cat.aeronaves, Object.fromEntries(cat.aeronaves.map((a) => [a, a])))}</label>
      <label>Desde <input type="date" name="desde" value="${esc(params.get('desde') || '')}"></label>
      <label>Hasta <input type="date" name="hasta" value="${esc(params.get('hasta') || '')}"></label>
      <button class="btn" type="submit">Filtrar</button>
      <button class="btn sec" type="button" id="limpiar">Quitar filtros</button>
    </form>
    <p class="resultado-meta">${filas.length} vuelos · ${num(horas)} horas realizadas en la selección</p>
    ${leyenda}
    <div class="tiras">${filas.length ? filas.map(tiraHTML).join('') : '<p class="vacio">Ningún vuelo coincide con los filtros. Pruebe ampliar el rango de fechas.</p>'}</div>`;
  document.getElementById('filtros').addEventListener('submit', (ev) => {
    ev.preventDefault();
    const p = new URLSearchParams([...new FormData(ev.target)].filter(([, v]) => v));
    location.hash = '#/vuelos' + (p.toString() ? '?' + p : '');
  });
  document.getElementById('limpiar').addEventListener('click', () => { location.hash = '#/vuelos'; });
}

async function vistaVuelo(id) {
  const { datos: v, evaluaciones, informe } = await api(`/vuelos/${id}`);
  document.title = `Vuelo ${id} – AeroLog`;
  $main.innerHTML = `
    <a class="volver" href="#/vuelos">Volver a vuelos</a>
    <div class="encabezado"><div><h1>Vuelo ${v.id_vuelo}</h1>
      <p class="sub">${TIPO[v.tipo_vuelo]} · ${fecha(v.fecha_vuelo)} · salida ${hora(v.hora_salida)}</p></div>${estado(v.estado)}</div>
    <section class="bloque">
      <div class="trayecto">
        <div class="aerod"><div class="oaci">${esc(v.aerodromo_origen)}</div><div class="ciudad">${esc(v.nombre_origen)}<br>${esc(v.ciudad_origen)}</div></div>
        <div class="recorrido"><span>${v.duracion != null ? num(v.duracion) + ' h' : 'pendiente'}</span></div>
        <div class="aerod"><div class="oaci">${esc(v.aerodromo_destino)}</div><div class="ciudad">${esc(v.nombre_destino)}<br>${esc(v.ciudad_destino)}</div></div>
      </div>
    </section>
    <section class="bloque"><dl class="ficha">
      <div><dt>Estudiante</dt><dd><a href="#/estudiantes/${v.id_estudiante}">${esc(v.estudiante)}</a> (${esc(v.codigo_estudiante)})</dd></div>
      <div><dt>Instructor</dt><dd>${v.instructor ? esc(v.instructor) : 'Sin instructor (vuelo solo)'}</dd></div>
      <div><dt>Aeronave</dt><dd><a href="#/flota/${esc(v.matricula)}">${esc(v.matricula)}</a> · ${esc(v.modelo)}</dd></div>
      <div><dt>Horómetro</dt><dd>${num(v.horometro_inicial)} → ${num(v.horometro_final)}</dd></div>
      <div><dt>Hora de llegada</dt><dd>${hora(v.hora_llegada)}</dd></div>
    </dl></section>
    <div class="rejilla dos">
      <section class="bloque"><h2>Maniobras evaluadas</h2>
        ${tablaHTML([{ t: 'Maniobra', k: 'maniobra' }, { t: 'Fase', f: (e) => esc(texto(e.fase)) },
          { t: 'Calificación', f: (e) => `<span class="calif" aria-label="${e.calificacion} de 5">${[1, 2, 3, 4, 5].map((n) => `<i class="${n <= e.calificacion ? 'on' : ''}"></i>`).join('')}</span> ${e.calificacion}/5` }],
          evaluaciones, { vacio: 'Este vuelo no tiene maniobras evaluadas.' })}</section>
      <section class="bloque"><h2>Informe del instructor</h2>
        ${informe ? `<p>${estado(informe.resultado)}</p><p class="det">Elaborado el ${fecha(informe.fecha_informe)}</p><p>${esc(informe.observaciones || 'Sin observaciones adicionales.')}</p>`
          : '<p class="vacio">Este vuelo no tiene informe. Solo los vuelos realizados con instructor lo tienen.</p>'}</section>
    </div>`;
}

async function vistaEstudiantes(params) {
  const q = params.get('q') || '';
  const filas = await api('/estudiantes' + (q ? `?q=${encodeURIComponent(q)}` : ''));
  document.title = 'Estudiantes – AeroLog';
  $main.innerHTML = `
    <div class="encabezado"><div><h1>Estudiantes</h1><p class="sub">Seleccione un estudiante para ver su bitácora de vuelo, sus matrículas y sus calificaciones.</p></div></div>
    <form class="filtros" id="buscar" role="search"><label>Buscar por nombre, código o documento
      <input type="search" name="q" value="${esc(q)}" placeholder="Ej.: Gómez o E-0003" autocomplete="off"></label>
      <button class="btn" type="submit">Buscar</button></form>
    <section class="bloque">${tablaHTML([
      { t: 'Código', k: 'codigo_estudiante' },
      { t: 'Nombre', f: (e) => `${esc(e.nombres)} ${esc(e.apellidos)}` },
      { t: 'Programa activo', f: (e) => esc(e.programa_activo || 'Sin matrícula activa') },
      { t: 'Vuelos', k: 'vuelos', num: true }, { t: 'Horas', f: (e) => num(e.horas), num: true },
      { t: 'Certificado médico', f: (e) => estado(e.estado_certificado) },
    ], filas, { enlace: (e) => `#/estudiantes/${e.id_persona}`, vacio: `No hay estudiantes que coincidan con “${q}”.` })}</section>`;
  document.getElementById('buscar').addEventListener('submit', (ev) => {
    ev.preventDefault();
    const v = new FormData(ev.target).get('q').trim();
    location.hash = '#/estudiantes' + (v ? `?q=${encodeURIComponent(v)}` : '');
  });
}

async function vistaEstudiante(id) {
  const d = await api(`/estudiantes/${id}`);
  const p = d.datos;
  document.title = `${p.nombres} ${p.apellidos} – AeroLog`;
  const roles = ['Estudiante', p.es_instructor && 'Instructor', p.es_tecnico && 'Técnico'].filter(Boolean).join(', ');
  const activa = d.matriculas.filter((m) => m.estado === 'ACTIVA');
  $main.innerHTML = `
    <a class="volver" href="#/estudiantes">Volver a estudiantes</a>
    <div class="encabezado"><div><h1>${esc(p.nombres)} ${esc(p.apellidos)}</h1>
      <p class="sub">${esc(p.codigo_estudiante)} · ${esc(roles)} · ${esc(p.correo)}</p></div>
      ${d.certificado ? estado(d.certificado.estado) : estado('SIN REGISTRO')}</div>
    <section class="bloque"><dl class="ficha">
      <div><dt>Documento</dt><dd>${esc(p.tipo_documento)} ${esc(p.numero_documento)}</dd></div>
      <div><dt>Edad</dt><dd>${p.edad} años</dd></div>
      <div><dt>Teléfono</dt><dd>${esc(p.telefono || 'No registrado')}</dd></div>
      <div><dt>Ingreso a la escuela</dt><dd>${fecha(p.fecha_ingreso)}</dd></div>
      <div><dt>Certificado médico</dt><dd>${d.certificado ? `Clase ${d.certificado.clase}, vence el ${fecha(d.certificado.fecha_vencimiento)}` : 'No registrado'}</dd></div>
    </dl></section>
    <div class="rejilla dos">
      <section class="bloque"><h2>Matrículas y avance en horas de vuelo</h2>
        ${d.matriculas.map((m) => {
          const pct = Math.min(100, 100 * (Number(m.horas) || 0) / Number(m.horas_minimas_vuelo));
          return `<div style="padding:10px 0;border-bottom:1px solid #E6EAF0">
            <div style="display:flex;justify-content:space-between;gap:10px"><strong>${esc(m.programa)}</strong>${estado(m.estado)}</div>
            <div class="det">Matriculado el ${fecha(m.fecha_matricula)} · pagado ${cop(m.total_pagado)} de ${cop(m.valor)}</div>
            ${m.estado === 'ACTIVA' ? `<div class="det">${num(m.horas)} de ${num(m.horas_minimas_vuelo)} horas mínimas (${num(pct)} %)</div><div class="progreso"><span style="width:${pct}%"></span></div>` : ''}
          </div>`;
        }).join('') || '<p class="vacio">Sin matrículas.</p>'}
        ${!activa.length ? '<p class="vacio">El estudiante no tiene una matrícula activa.</p>' : ''}
      </section>
      <section class="bloque"><h2>Horas por tipo de vuelo</h2>
        ${d.resumen.length ? barrasHTML(d.resumen.map((r) => ({ ...r, tipo: TIPO[r.tipo] })), 'tipo', 'horas', ' h') : '<p class="vacio">Aún no registra vuelos realizados.</p>'}</section>
    </div>
    <section class="bloque"><h2>Bitácora de vuelo (${d.bitacora.length})</h2>${leyenda}
      <div class="tiras">${d.bitacora.map((v) => tiraHTML({ ...v, estudiante: '' })).join('') || '<p class="vacio">Sin vuelos registrados.</p>'}</div></section>
    <section class="bloque"><h2>Calificaciones de cursos teóricos</h2>${tablaHTML([
      { t: 'Curso', k: 'curso' }, { t: 'Nota final', f: (c) => num(c.nota_final), num: true },
      { t: 'Fecha', f: (c) => fecha(c.fecha_calificacion) }, { t: 'Estado', f: (c) => estado(c.estado) }],
      d.calificaciones, { vacio: 'No hay calificaciones registradas.' })}</section>`;
}

async function vistaInstructores() {
  const filas = await api('/instructores');
  document.title = 'Instructores – AeroLog';
  $main.innerHTML = `
    <h1>Instructores</h1><p class="sub">Licencias, modelos en los que cada instructor está habilitado y vuelos impartidos.</p>
    <section class="bloque">${tablaHTML([
      { t: 'Instructor', f: (i) => `<strong>${esc(i.nombre)}</strong>${i.tambien_estudiante ? '<div class="det">También es estudiante</div>' : ''}${i.tambien_tecnico ? '<div class="det">También es técnico</div>' : ''}` },
      { t: 'Licencia', f: (i) => `${esc(i.numero_licencia)}<div class="det">vence ${fecha(i.fecha_venc_licencia)}</div>` },
      { t: 'Estado', f: (i) => estado(i.estado_licencia) },
      { t: 'Habilitado en', f: (i) => esc(i.habilitaciones || '—') },
      { t: 'Vuelos', k: 'vuelos', num: true }, { t: 'Horas', f: (i) => num(i.horas), num: true }], filas)}</section>`;
}

async function vistaFlota() {
  const filas = await api('/aeronaves');
  document.title = 'Flota – AeroLog';
  $main.innerHTML = `
    <h1>Flota</h1><p class="sub">Aeronaves de entrenamiento, su estado operativo y la vigencia de su certificado de aeronavegabilidad.</p>
    <div class="colas">${filas.map((a) => `<a class="cola" href="#/flota/${esc(a.matricula)}">
      <div class="cabeza"><span class="matricula">${esc(a.matricula)}</span>${estado(a.estado)}</div>
      <div>${esc(a.modelo)} · ${esc(a.fabricante)}</div>
      <div class="linea"><span>${a.numero_motores === 2 ? 'Bimotor' : 'Monomotor'} · ${a.anio_fabricacion}</span><span>${num(a.horas_totales)} h totales</span></div>
      <div class="linea"><span>Certificado ${esc(texto(a.estado_certificado)).toLowerCase()}</span><span>${a.venc_certificado ? fecha(a.venc_certificado) : ''}</span></div>
      <div class="linea"><span>${a.vuelos} vuelos registrados</span><span>${num(a.horas_voladas)} h de instrucción</span></div>
    </a>`).join('')}</div>`;
}

async function vistaAeronave(matricula) {
  const d = await api(`/aeronaves/${encodeURIComponent(matricula)}`);
  const a = d.datos;
  document.title = `${a.matricula} – AeroLog`;
  $main.innerHTML = `
    <a class="volver" href="#/flota">Volver a la flota</a>
    <div class="encabezado"><div><h1>${esc(a.matricula)}</h1><p class="sub">${esc(a.modelo)} · ${esc(a.fabricante)} (${esc(a.pais_origen)})</p></div>${estado(a.estado)}</div>
    <section class="bloque"><dl class="ficha">
      <div><dt>Año de fabricación</dt><dd>${a.anio_fabricacion}</dd></div>
      <div><dt>Horas totales</dt><dd>${num(a.horas_totales)}</dd></div>
      <div><dt>Motores</dt><dd>${a.numero_motores}</dd></div>
      <div><dt>Asientos</dt><dd>${a.capacidad_asientos}</dd></div>
      <div><dt>Velocidad de crucero</dt><dd>${a.velocidad_crucero_kt} nudos</dd></div>
      <div><dt>Certificado de aeronavegabilidad</dt><dd>${a.numero_certificado ? `${esc(a.numero_certificado)}, vence ${fecha(a.venc_certificado)}` : 'No registrado'}</dd></div>
    </dl></section>
    <div class="rejilla dos">
      <section class="bloque"><h2>Órdenes de mantenimiento</h2>${tablaHTML([
        { t: 'Orden', k: 'id_orden' }, { t: 'Tipo', f: (o) => esc(texto(o.tipo_orden)) }, { t: 'Apertura', f: (o) => fecha(o.fecha_apertura) },
        { t: 'Estado', f: (o) => estado(o.fecha_cierre ? 'CERRADA' : 'ABIERTA') }, { t: 'Repuestos', f: (o) => cop(o.costo_repuestos), num: true }],
        d.ordenes, { enlace: (o) => `#/mantenimiento/${o.id_orden}`, vacio: 'Sin órdenes de mantenimiento.' })}</section>
      <section class="bloque"><h2>Instructores habilitados en el modelo</h2>${tablaHTML([
        { t: 'Instructor', k: 'instructor' }, { t: 'Habilitado desde', f: (h) => fecha(h.fecha_habilitacion) }], d.habilitados,
        { vacio: 'Ningún instructor está habilitado en este modelo.' })}</section>
    </div>
    <section class="bloque"><h2>Últimos vuelos</h2>${leyenda}<div class="tiras">${d.vuelos.map((v) => tiraHTML({ ...v, matricula: a.matricula, modelo: a.modelo })).join('') || '<p class="vacio">Sin vuelos.</p>'}</div></section>`;
}

async function vistaMantenimiento(params) {
  const est = params.get('estado') || '';
  const filas = await api('/mantenimiento' + (est ? `?estado=${est}` : ''));
  document.title = 'Mantenimiento – AeroLog';
  const total = filas.reduce((s, o) => s + Number(o.costo_repuestos), 0);
  $main.innerHTML = `
    <div class="encabezado"><div><h1>Mantenimiento</h1><p class="sub">Órdenes de trabajo, técnicos asignados y costo de los repuestos instalados.</p></div>
      <form class="filtros" id="f" style="margin:0"><label>Mostrar <select name="estado">
        <option value="">Todas las órdenes</option><option value="abiertas" ${est === 'abiertas' ? 'selected' : ''}>Abiertas</option>
        <option value="cerradas" ${est === 'cerradas' ? 'selected' : ''}>Cerradas</option></select></label></form></div>
    <p class="resultado-meta">${filas.length} órdenes · ${cop(total)} en repuestos</p>
    <section class="bloque">${tablaHTML([
      { t: 'Orden', k: 'id_orden' }, { t: 'Aeronave', k: 'matricula' }, { t: 'Tipo', f: (o) => esc(texto(o.tipo_orden)) },
      { t: 'Apertura', f: (o) => fecha(o.fecha_apertura) }, { t: 'Cierre', f: (o) => fecha(o.fecha_cierre) }, { t: 'Estado', f: (o) => estado(o.estado) },
      { t: 'Técnicos', k: 'tecnicos', num: true }, { t: 'Horas', f: (o) => num(o.horas_tecnicos), num: true },
      { t: 'Repuestos', f: (o) => cop(o.costo_repuestos), num: true }], filas, { enlace: (o) => `#/mantenimiento/${o.id_orden}` })}</section>`;
  document.querySelector('#f select').addEventListener('change', (ev) => {
    location.hash = '#/mantenimiento' + (ev.target.value ? `?estado=${ev.target.value}` : '');
  });
}

async function vistaOrden(id) {
  const d = await api(`/mantenimiento/${id}`);
  const o = d.datos;
  const total = d.repuestos.reduce((s, r) => s + Number(r.subtotal), 0);
  document.title = `Orden ${id} – AeroLog`;
  $main.innerHTML = `
    <a class="volver" href="#/mantenimiento">Volver a mantenimiento</a>
    <div class="encabezado"><div><h1>Orden de trabajo ${o.id_orden}</h1><p class="sub">${esc(texto(o.tipo_orden))} de la aeronave <a href="#/flota/${esc(o.matricula)}">${esc(o.matricula)}</a> (${esc(o.modelo)})</p></div>${estado(o.estado)}</div>
    <section class="bloque"><dl class="ficha">
      <div><dt>Apertura</dt><dd>${fecha(o.fecha_apertura)}</dd></div><div><dt>Cierre</dt><dd>${fecha(o.fecha_cierre)}</dd></div>
      <div><dt>Horas de la aeronave</dt><dd>${num(o.horas_aeronave)}</dd></div><div><dt>Costo de repuestos</dt><dd>${cop(total)}</dd></div>
    </dl><p style="margin:16px 0 0">${esc(o.descripcion)}</p></section>
    <section class="bloque"><h2>Técnicos</h2>${tablaHTML([{ t: 'Técnico', k: 'tecnico' }, { t: 'Especialidad', f: (t) => esc(texto(t.especialidad)) },
      { t: 'Horas', f: (t) => num(t.horas_trabajadas), num: true }, { t: 'Labor realizada', k: 'labor_realizada' }], d.tecnicos)}</section>
    <section class="bloque"><h2>Repuestos instalados</h2>${tablaHTML([{ t: 'Número de parte', k: 'numero_parte' }, { t: 'Descripción', k: 'descripcion' },
      { t: 'Cantidad', k: 'cantidad', num: true }, { t: 'Costo unitario', f: (r) => cop(r.costo_unitario), num: true },
      { t: 'Subtotal', f: (r) => cop(r.subtotal), num: true }, { t: 'Serie', f: (r) => esc(r.numero_serie || '—') }, { t: 'Proveedor', k: 'proveedor' }],
      d.repuestos, { vacio: 'No se instalaron repuestos.' })}</section>`;
}

async function vistaAcademico() {
  const programas = await api('/academico');
  document.title = 'Programas académicos – AeroLog';
  $main.innerHTML = `<h1>Programas académicos</h1><p class="sub">Plan de estudios de cada programa, matrículas activas y desempeño en los cursos teóricos.</p>
    ${programas.map((p) => {
      const etapas = [...new Set(p.cursos.map((c) => c.etapa))];
      return `<section class="bloque">
        <div class="encabezado" style="margin-bottom:12px"><h2 style="margin:0">${esc(p.nombre)}</h2><span class="det">${p.activos} matrículas activas de ${p.matriculas}</span></div>
        <dl class="ficha" style="margin-bottom:16px"><div><dt>Horas mínimas de vuelo</dt><dd>${num(p.horas_minimas_vuelo, 0)}</dd></div>
          <div><dt>Duración</dt><dd>${p.duracion_meses} meses</dd></div><div><dt>Valor</dt><dd>${cop(p.valor)}</dd></div>
          <div><dt>Cursos teóricos</dt><dd>${p.cursos.length}</dd></div></dl>
        ${etapas.map((e) => `<h3>Etapa ${e}</h3>${tablaHTML([{ t: 'Curso', k: 'nombre' }, { t: 'Intensidad', f: (c) => `${c.intensidad_horaria} h`, num: true },
          { t: 'Promedio de notas', f: (c) => num(c.promedio, 2), num: true }, { t: 'Notas reprobatorias', k: 'reprobados', num: true }],
          p.cursos.filter((c) => c.etapa === e))}`).join('')}
      </section>`;
    }).join('')}`;
}

let _listaConsultas = null;
const algebraHTML = (linea) => esc(linea).replace(/\{s:([^}]*)\}/g, '<sub>$1</sub>');
async function vistaConsultas(n) {
  if (!_listaConsultas) _listaConsultas = await api('/consultas');
  document.title = 'Consultas de álgebra relacional – AeroLog';
  let actual = '<p class="vacio">Seleccione una pregunta de la lista para ver su expresión en álgebra relacional y ejecutarla sobre la base de datos.</p>';
  if (n) {
    const c = await api(`/consultas/${n}`);
    actual = `<span class="det">Ejercicio ${c.n} · ${esc(c.categoria)}</span>
      <h2 style="margin-top:4px">${esc(c.pregunta)}</h2>
      <h3>Álgebra relacional</h3><div class="algebra">${c.algebra.map((l) => `<div>${algebraHTML(l)}</div>`).join('')}</div>
      <p>${algebraHTML(c.explicacion)}</p>
      <h3>Sentencia SQL ejecutada</h3><pre class="sql">${esc(c.sql)}</pre>
      <h3>Resultado</h3><p class="resultado-meta">${c.total} ${c.total === 1 ? 'tupla' : 'tuplas'}</p>
      ${c.total ? tablaHTML(c.columnas.map((col, i) => ({ t: col, f: (f) => esc(f[i] ?? 'NULL') })), c.filas)
        : '<p class="vacio">La consulta no devolvió tuplas. En las consultas de auditoría, un resultado vacío indica que la regla se cumple.</p>'}`;
  }
  let cat = '';
  const lista = _listaConsultas.map((c) => {
    const h = c.categoria !== cat ? `<h3>${esc((cat = c.categoria))}</h3>` : '';
    return `${h}<a href="#/consultas/${c.n}" ${String(c.n) === String(n) ? 'aria-current="true"' : ''}><b>${c.n}</b><span>${esc(c.pregunta)}</span></a>`;
  }).join('');
  $main.innerHTML = `<h1>Consultas de álgebra relacional</h1>
    <p class="sub">Las ${_listaConsultas.length} preguntas del documento de implementación, ejecutadas en vivo sobre PostgreSQL con su sentencia SQL equivalente.</p>
    <div class="consultas"><nav class="bloque lista-consultas" aria-label="Preguntas">${lista}</nav><section class="bloque">${actual}</section></div>`;
  const marcada = document.querySelector('.lista-consultas a[aria-current="true"]');
  if (marcada) marcada.scrollIntoView({ block: 'nearest' });
}

async function vistaEstado() {
  document.title = 'Estado de la conexión – AeroLog';
  try {
    const d = await api('/estado');
    const s = d.servidor;
    $main.innerHTML = `<h1>Estado de la conexión</h1><p class="sub">La aplicación está conectada a la base de datos y puede leer sus datos.</p>
      <section class="bloque"><dl class="ficha">
        <div><dt>Base de datos</dt><dd>${esc(s.base_datos)}</dd></div><div><dt>Usuario</dt><dd>${esc(s.usuario)}</dd></div>
        <div><dt>Servidor</dt><dd>${esc(s.servidor || 'socket local')}:${esc(s.puerto || '')}</dd></div>
        <div><dt>Hora del servidor</dt><dd>${esc(s.fecha_servidor)}</dd></div>
        <div><dt>Modo</dt><dd>${s.solo_lectura === 'on' ? 'Solo lectura' : 'Lectura y escritura'}</dd></div>
        <div><dt>Tablas</dt><dd>${d.tablas}</dd></div></dl>
        <p class="det" style="margin:16px 0 0">${esc(s.version)}</p></section>
      <section class="bloque"><h2>Registros en las tablas principales</h2>${barrasHTML(Object.entries(d.conteos).map(([t, n]) => ({ t, n })), 't', 'n')}</section>`;
  } catch (e) {
    $main.innerHTML = `<h1>Estado de la conexión</h1><div class="error-caja"><p><strong>La aplicación no puede conectarse a la base de datos.</strong></p><p><code>${esc(e.message)}</code></p>
      <p>Revise que la máquina virtual esté encendida, que el servicio postgresql-18 esté activo, que el puerto 5432 esté reenviado y que el usuario y la contraseña del archivo .env sean correctos.</p></div>`;
  }
}

// ------------------------------------------------------------------ enrutador
const rutas = [
  [/^\/?$|^\/panel$/, () => vistaPanel(), 'panel'],
  [/^\/vuelos$/, (m, p) => vistaVuelos(p), 'vuelos'],
  [/^\/vuelos\/(\d+)$/, (m) => vistaVuelo(m[1]), 'vuelos'],
  [/^\/estudiantes$/, (m, p) => vistaEstudiantes(p), 'estudiantes'],
  [/^\/estudiantes\/(\d+)$/, (m) => vistaEstudiante(m[1]), 'estudiantes'],
  [/^\/instructores$/, () => vistaInstructores(), 'instructores'],
  [/^\/flota$/, () => vistaFlota(), 'flota'],
  [/^\/flota\/([\w-]+)$/, (m) => vistaAeronave(m[1]), 'flota'],
  [/^\/mantenimiento$/, (m, p) => vistaMantenimiento(p), 'mantenimiento'],
  [/^\/mantenimiento\/(\d+)$/, (m) => vistaOrden(m[1]), 'mantenimiento'],
  [/^\/academico$/, () => vistaAcademico(), 'academico'],
  [/^\/consultas$/, () => vistaConsultas(null), 'consultas'],
  [/^\/consultas\/(\d+)$/, (m) => vistaConsultas(m[1]), 'consultas'],
  [/^\/estado$/, () => vistaEstado(), 'estado'],
];

async function navegar() {
  const [ruta, query] = (location.hash.slice(1) || '/panel').split('?');
  const params = new URLSearchParams(query || '');
  for (const [re, vista, sec] of rutas) {
    const m = ruta.match(re);
    if (!m) continue;
    document.querySelectorAll('[data-sec]').forEach((a) => { if (a.dataset.sec === sec) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current'); });
    cerrarMenu();
    cargando();
    try { await vista(m, params); } catch (e) { mostrarError(e); }
    $main.focus({ preventScroll: true });
    window.scrollTo(0, 0);
    return;
  }
  $main.innerHTML = '<h1>Sección no encontrada</h1><p class="sub">La dirección no corresponde a ninguna sección. <a href="#/panel">Ir al panel de operaciones</a>.</p>';
}

// filas de tabla con enlace (clic y teclado)
$main.addEventListener('click', (ev) => { const tr = ev.target.closest('tr[data-href]'); if (tr && !ev.target.closest('a')) location.hash = tr.dataset.href; });
$main.addEventListener('keydown', (ev) => { const tr = ev.target.closest('tr[data-href]'); if (tr && ev.key === 'Enter') location.hash = tr.dataset.href; });

// menú móvil
const $menu = document.getElementById('menu');
const $lateral = document.getElementById('lateral');
function cerrarMenu() { $lateral.classList.remove('abierto'); $menu.setAttribute('aria-expanded', 'false'); }
$menu.addEventListener('click', () => { const ab = $lateral.classList.toggle('abierto'); $menu.setAttribute('aria-expanded', String(ab)); });

// indicador de conexión
async function verificarConexion() {
  const el = document.getElementById('conexion');
  const txt = document.getElementById('conexion-texto');
  try {
    const d = await api('/estado');
    el.className = 'conexion ok'; txt.textContent = `Conectado a ${d.servidor.base_datos}`;
  } catch (e) {
    el.className = 'conexion error'; txt.textContent = 'Sin conexión a la base de datos';
  }
}

window.addEventListener('hashchange', navegar);
navegar();
verificarConexion();
