-- =====================================================================
-- AeroLog - Script de creación de objetos
-- RDBMS: PostgreSQL 18 | Base de datos: aerolog
-- Generado: 2026-10-28
-- =====================================================================

BEGIN;

-- Eliminación en orden inverso a las dependencias (permite re-ejecutar el script)
DROP TABLE IF EXISTS detalle_repuesto CASCADE;
DROP TABLE IF EXISTS repuesto CASCADE;
DROP TABLE IF EXISTS proveedor CASCADE;
DROP TABLE IF EXISTS asignacion_tecnico CASCADE;
DROP TABLE IF EXISTS orden_trabajo CASCADE;
DROP TABLE IF EXISTS evaluacion_maniobra CASCADE;
DROP TABLE IF EXISTS maniobra CASCADE;
DROP TABLE IF EXISTS informe_vuelo CASCADE;
DROP TABLE IF EXISTS vuelo CASCADE;
DROP TABLE IF EXISTS aerodromo CASCADE;
DROP TABLE IF EXISTS habilitacion CASCADE;
DROP TABLE IF EXISTS cert_aeronavegabilidad CASCADE;
DROP TABLE IF EXISTS aeronave CASCADE;
DROP TABLE IF EXISTS modelo_aeronave CASCADE;
DROP TABLE IF EXISTS fabricante CASCADE;
DROP TABLE IF EXISTS pago CASCADE;
DROP TABLE IF EXISTS calificacion CASCADE;
DROP TABLE IF EXISTS matricula CASCADE;
DROP TABLE IF EXISTS plan_estudios CASCADE;
DROP TABLE IF EXISTS curso CASCADE;
DROP TABLE IF EXISTS programa CASCADE;
DROP TABLE IF EXISTS certificado_medico CASCADE;
DROP TABLE IF EXISTS tecnico CASCADE;
DROP TABLE IF EXISTS instructor CASCADE;
DROP TABLE IF EXISTS estudiante CASCADE;
DROP TABLE IF EXISTS persona CASCADE;

-- Supertipo que almacena los datos comunes de toda persona vinculada a la escuela.
CREATE TABLE persona (
    id_persona INT NOT NULL,
    tipo_documento VARCHAR(3) NOT NULL,
    numero_documento VARCHAR(15) NOT NULL,
    nombres VARCHAR(60) NOT NULL,
    apellidos VARCHAR(60) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(15),
    correo VARCHAR(100) NOT NULL,
    CONSTRAINT pk_persona PRIMARY KEY (id_persona),
    CONSTRAINT uq_persona_correo UNIQUE (correo),
    CONSTRAINT uq_persona_1 UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT ck_persona_tipo_documento CHECK (tipo_documento IN ('CC','CE','PA','TI'))
);
COMMENT ON TABLE persona IS 'Supertipo que almacena los datos comunes de toda persona vinculada a la escuela.';
COMMENT ON COLUMN persona.id_persona IS 'Identificador único de la persona.';
COMMENT ON COLUMN persona.tipo_documento IS 'Tipo de documento de identidad.';
COMMENT ON COLUMN persona.numero_documento IS 'Número del documento de identidad.';
COMMENT ON COLUMN persona.nombres IS 'Nombres de la persona.';
COMMENT ON COLUMN persona.apellidos IS 'Apellidos de la persona.';
COMMENT ON COLUMN persona.fecha_nacimiento IS 'Fecha de nacimiento.';
COMMENT ON COLUMN persona.telefono IS 'Número telefónico de contacto.';
COMMENT ON COLUMN persona.correo IS 'Correo electrónico.';

-- Subtipo de PERSONA que recibe instrucción teórica y de vuelo.
CREATE TABLE estudiante (
    id_persona INT NOT NULL,
    codigo_estudiante VARCHAR(10) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    CONSTRAINT pk_estudiante PRIMARY KEY (id_persona),
    CONSTRAINT uq_estudiante_codigo_estudiante UNIQUE (codigo_estudiante),
    CONSTRAINT fk_estudiante_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona)
);
COMMENT ON TABLE estudiante IS 'Subtipo de PERSONA que recibe instrucción teórica y de vuelo.';
COMMENT ON COLUMN estudiante.id_persona IS 'Identificador de la persona que es estudiante.';
COMMENT ON COLUMN estudiante.codigo_estudiante IS 'Código estudiantil asignado por la escuela.';
COMMENT ON COLUMN estudiante.fecha_ingreso IS 'Fecha de ingreso a la escuela.';

-- Subtipo de PERSONA habilitada para impartir instrucción de vuelo.
CREATE TABLE instructor (
    id_persona INT NOT NULL,
    numero_licencia VARCHAR(15) NOT NULL,
    fecha_venc_licencia DATE NOT NULL,
    CONSTRAINT pk_instructor PRIMARY KEY (id_persona),
    CONSTRAINT uq_instructor_numero_licencia UNIQUE (numero_licencia),
    CONSTRAINT fk_instructor_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona)
);
COMMENT ON TABLE instructor IS 'Subtipo de PERSONA habilitada para impartir instrucción de vuelo.';
COMMENT ON COLUMN instructor.id_persona IS 'Identificador de la persona que es instructor.';
COMMENT ON COLUMN instructor.numero_licencia IS 'Número de la licencia de instructor de vuelo.';
COMMENT ON COLUMN instructor.fecha_venc_licencia IS 'Fecha de vencimiento de la licencia.';

-- Subtipo de PERSONA que ejecuta labores de mantenimiento aeronáutico.
CREATE TABLE tecnico (
    id_persona INT NOT NULL,
    numero_licencia VARCHAR(15) NOT NULL,
    especialidad VARCHAR(15) NOT NULL,
    CONSTRAINT pk_tecnico PRIMARY KEY (id_persona),
    CONSTRAINT uq_tecnico_numero_licencia UNIQUE (numero_licencia),
    CONSTRAINT ck_tecnico_especialidad CHECK (especialidad IN ('MOTORES','AVIONICA','ESTRUCTURAS')),
    CONSTRAINT fk_tecnico_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona)
);
COMMENT ON TABLE tecnico IS 'Subtipo de PERSONA que ejecuta labores de mantenimiento aeronáutico.';
COMMENT ON COLUMN tecnico.id_persona IS 'Identificador de la persona que es técnico.';
COMMENT ON COLUMN tecnico.numero_licencia IS 'Número de la licencia técnica.';
COMMENT ON COLUMN tecnico.especialidad IS 'Especialidad técnica.';

-- Certificado médico aeronáutico vigente de cada estudiante.
CREATE TABLE certificado_medico (
    id_certificado INT NOT NULL,
    id_estudiante INT NOT NULL,
    numero_certificado VARCHAR(20) NOT NULL,
    clase SMALLINT NOT NULL,
    fecha_expedicion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    CONSTRAINT pk_certificado_medico PRIMARY KEY (id_certificado),
    CONSTRAINT uq_certificado_medico_id_estudiante UNIQUE (id_estudiante),
    CONSTRAINT uq_certificado_medico_numero_certificado UNIQUE (numero_certificado),
    CONSTRAINT ck_certificado_medico_clase CHECK (clase BETWEEN 1 AND 3),
    CONSTRAINT ck_certificado_medico_fecha_vencimiento CHECK (fecha_vencimiento > fecha_expedicion),
    CONSTRAINT fk_certificado_medico_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiante (id_persona)
);
COMMENT ON TABLE certificado_medico IS 'Certificado médico aeronáutico vigente de cada estudiante.';
COMMENT ON COLUMN certificado_medico.id_certificado IS 'Identificador del certificado médico.';
COMMENT ON COLUMN certificado_medico.id_estudiante IS 'Estudiante titular del certificado.';
COMMENT ON COLUMN certificado_medico.numero_certificado IS 'Número del certificado expedido.';
COMMENT ON COLUMN certificado_medico.clase IS 'Clase del certificado médico.';
COMMENT ON COLUMN certificado_medico.fecha_expedicion IS 'Fecha de expedición.';
COMMENT ON COLUMN certificado_medico.fecha_vencimiento IS 'Fecha de vencimiento.';

-- Programa de formación ofrecido por la escuela.
CREATE TABLE programa (
    id_programa INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    horas_minimas_vuelo DECIMAL(6,1) NOT NULL,
    duracion_meses SMALLINT NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_programa PRIMARY KEY (id_programa),
    CONSTRAINT uq_programa_nombre UNIQUE (nombre),
    CONSTRAINT ck_programa_horas_minimas_vuelo CHECK (horas_minimas_vuelo > 0),
    CONSTRAINT ck_programa_duracion_meses CHECK (duracion_meses > 0),
    CONSTRAINT ck_programa_valor CHECK (valor > 0)
);
COMMENT ON TABLE programa IS 'Programa de formación ofrecido por la escuela.';
COMMENT ON COLUMN programa.id_programa IS 'Identificador del programa.';
COMMENT ON COLUMN programa.nombre IS 'Nombre del programa.';
COMMENT ON COLUMN programa.horas_minimas_vuelo IS 'Horas mínimas de vuelo exigidas.';
COMMENT ON COLUMN programa.duracion_meses IS 'Duración estimada en meses.';
COMMENT ON COLUMN programa.valor IS 'Valor del programa en pesos colombianos.';

-- Curso teórico que puede hacer parte de uno o varios programas.
CREATE TABLE curso (
    id_curso INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    intensidad_horaria SMALLINT NOT NULL,
    CONSTRAINT pk_curso PRIMARY KEY (id_curso),
    CONSTRAINT uq_curso_nombre UNIQUE (nombre),
    CONSTRAINT ck_curso_intensidad_horaria CHECK (intensidad_horaria > 0)
);
COMMENT ON TABLE curso IS 'Curso teórico que puede hacer parte de uno o varios programas.';
COMMENT ON COLUMN curso.id_curso IS 'Identificador del curso.';
COMMENT ON COLUMN curso.nombre IS 'Nombre del curso.';
COMMENT ON COLUMN curso.intensidad_horaria IS 'Número de horas teóricas del curso.';

-- Tabla asociativa que define qué cursos componen cada programa.
CREATE TABLE plan_estudios (
    id_programa INT NOT NULL,
    id_curso INT NOT NULL,
    etapa SMALLINT NOT NULL,
    CONSTRAINT pk_plan_estudios PRIMARY KEY (id_programa, id_curso),
    CONSTRAINT ck_plan_estudios_etapa CHECK (etapa > 0),
    CONSTRAINT fk_plan_estudios_id_programa FOREIGN KEY (id_programa) REFERENCES programa (id_programa),
    CONSTRAINT fk_plan_estudios_id_curso FOREIGN KEY (id_curso) REFERENCES curso (id_curso)
);
COMMENT ON TABLE plan_estudios IS 'Tabla asociativa que define qué cursos componen cada programa.';
COMMENT ON COLUMN plan_estudios.id_programa IS 'Programa al que pertenece el curso.';
COMMENT ON COLUMN plan_estudios.id_curso IS 'Curso incluido en el programa.';
COMMENT ON COLUMN plan_estudios.etapa IS 'Etapa del programa en la que se cursa.';

-- Inscripción de un estudiante en un programa de formación.
CREATE TABLE matricula (
    id_matricula INT NOT NULL,
    id_estudiante INT NOT NULL,
    id_programa INT NOT NULL,
    fecha_matricula DATE NOT NULL,
    estado VARCHAR(12) NOT NULL,
    CONSTRAINT pk_matricula PRIMARY KEY (id_matricula),
    CONSTRAINT uq_matricula_1 UNIQUE (id_estudiante, id_programa, fecha_matricula),
    CONSTRAINT ck_matricula_estado CHECK (estado IN ('ACTIVA','SUSPENDIDA','FINALIZADA','RETIRADA')),
    CONSTRAINT fk_matricula_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiante (id_persona),
    CONSTRAINT fk_matricula_id_programa FOREIGN KEY (id_programa) REFERENCES programa (id_programa)
);
COMMENT ON TABLE matricula IS 'Inscripción de un estudiante en un programa de formación.';
COMMENT ON COLUMN matricula.id_matricula IS 'Identificador de la matrícula.';
COMMENT ON COLUMN matricula.id_estudiante IS 'Estudiante matriculado.';
COMMENT ON COLUMN matricula.id_programa IS 'Programa en el que se matricula.';
COMMENT ON COLUMN matricula.fecha_matricula IS 'Fecha de la matrícula.';
COMMENT ON COLUMN matricula.estado IS 'Estado de la matrícula.';

-- Tabla asociativa con la nota final de un estudiante en un curso.
CREATE TABLE calificacion (
    id_estudiante INT NOT NULL,
    id_curso INT NOT NULL,
    nota_final DECIMAL(2,1) NOT NULL,
    fecha_calificacion DATE NOT NULL,
    CONSTRAINT pk_calificacion PRIMARY KEY (id_estudiante, id_curso),
    CONSTRAINT ck_calificacion_nota_final CHECK (nota_final BETWEEN 0 AND 5),
    CONSTRAINT fk_calificacion_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiante (id_persona),
    CONSTRAINT fk_calificacion_id_curso FOREIGN KEY (id_curso) REFERENCES curso (id_curso)
);
COMMENT ON TABLE calificacion IS 'Tabla asociativa con la nota final de un estudiante en un curso.';
COMMENT ON COLUMN calificacion.id_estudiante IS 'Estudiante calificado.';
COMMENT ON COLUMN calificacion.id_curso IS 'Curso calificado.';
COMMENT ON COLUMN calificacion.nota_final IS 'Nota final en escala de 0.0 a 5.0.';
COMMENT ON COLUMN calificacion.fecha_calificacion IS 'Fecha de registro de la nota.';

-- Pago realizado por un estudiante asociado a una matrícula.
CREATE TABLE pago (
    id_pago INT NOT NULL,
    id_matricula INT NOT NULL,
    fecha_pago DATE NOT NULL,
    concepto VARCHAR(15) NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    medio_pago VARCHAR(15) NOT NULL,
    CONSTRAINT pk_pago PRIMARY KEY (id_pago),
    CONSTRAINT ck_pago_concepto CHECK (concepto IN ('MATRICULA','PAQUETE_HORAS','CURSO','OTRO')),
    CONSTRAINT ck_pago_valor CHECK (valor > 0),
    CONSTRAINT ck_pago_medio_pago CHECK (medio_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
    CONSTRAINT fk_pago_id_matricula FOREIGN KEY (id_matricula) REFERENCES matricula (id_matricula)
);
COMMENT ON TABLE pago IS 'Pago realizado por un estudiante asociado a una matrícula.';
COMMENT ON COLUMN pago.id_pago IS 'Identificador del pago.';
COMMENT ON COLUMN pago.id_matricula IS 'Matrícula a la que se abona el pago.';
COMMENT ON COLUMN pago.fecha_pago IS 'Fecha del pago.';
COMMENT ON COLUMN pago.concepto IS 'Concepto del pago.';
COMMENT ON COLUMN pago.valor IS 'Valor pagado.';
COMMENT ON COLUMN pago.medio_pago IS 'Medio de pago utilizado.';

-- Fabricante de aeronaves.
CREATE TABLE fabricante (
    id_fabricante INT NOT NULL,
    nombre VARCHAR(60) NOT NULL,
    pais_origen VARCHAR(40) NOT NULL,
    CONSTRAINT pk_fabricante PRIMARY KEY (id_fabricante),
    CONSTRAINT uq_fabricante_nombre UNIQUE (nombre)
);
COMMENT ON TABLE fabricante IS 'Fabricante de aeronaves.';
COMMENT ON COLUMN fabricante.id_fabricante IS 'Identificador del fabricante.';
COMMENT ON COLUMN fabricante.nombre IS 'Nombre del fabricante.';
COMMENT ON COLUMN fabricante.pais_origen IS 'País de origen del fabricante.';

-- Modelo de aeronave producido por un fabricante.
CREATE TABLE modelo_aeronave (
    id_modelo INT NOT NULL,
    id_fabricante INT NOT NULL,
    nombre VARCHAR(40) NOT NULL,
    numero_motores SMALLINT NOT NULL,
    capacidad_asientos SMALLINT NOT NULL,
    velocidad_crucero_kt SMALLINT NOT NULL,
    CONSTRAINT pk_modelo_aeronave PRIMARY KEY (id_modelo),
    CONSTRAINT uq_modelo_aeronave_1 UNIQUE (id_fabricante, nombre),
    CONSTRAINT ck_modelo_aeronave_numero_motores CHECK (numero_motores IN (1, 2)),
    CONSTRAINT ck_modelo_aeronave_capacidad_asientos CHECK (capacidad_asientos > 0),
    CONSTRAINT ck_modelo_aeronave_velocidad_crucero_kt CHECK (velocidad_crucero_kt > 0),
    CONSTRAINT fk_modelo_aeronave_id_fabricante FOREIGN KEY (id_fabricante) REFERENCES fabricante (id_fabricante)
);
COMMENT ON TABLE modelo_aeronave IS 'Modelo de aeronave producido por un fabricante.';
COMMENT ON COLUMN modelo_aeronave.id_modelo IS 'Identificador del modelo.';
COMMENT ON COLUMN modelo_aeronave.id_fabricante IS 'Fabricante del modelo.';
COMMENT ON COLUMN modelo_aeronave.nombre IS 'Nombre comercial del modelo.';
COMMENT ON COLUMN modelo_aeronave.numero_motores IS 'Número de motores.';
COMMENT ON COLUMN modelo_aeronave.capacidad_asientos IS 'Número de asientos.';
COMMENT ON COLUMN modelo_aeronave.velocidad_crucero_kt IS 'Velocidad de crucero en nudos.';

-- Aeronave de la flota identificada por su matrícula.
CREATE TABLE aeronave (
    matricula VARCHAR(10) NOT NULL,
    id_modelo INT NOT NULL,
    anio_fabricacion SMALLINT NOT NULL,
    horas_totales DECIMAL(8,1) NOT NULL,
    estado VARCHAR(17) NOT NULL,
    CONSTRAINT pk_aeronave PRIMARY KEY (matricula),
    CONSTRAINT ck_aeronave_horas_totales CHECK (horas_totales >= 0),
    CONSTRAINT ck_aeronave_estado CHECK (estado IN ('DISPONIBLE','EN_MANTENIMIENTO','FUERA_DE_SERVICIO')),
    CONSTRAINT fk_aeronave_id_modelo FOREIGN KEY (id_modelo) REFERENCES modelo_aeronave (id_modelo)
);
COMMENT ON TABLE aeronave IS 'Aeronave de la flota identificada por su matrícula.';
COMMENT ON COLUMN aeronave.matricula IS 'Matrícula de la aeronave (por ejemplo, HK-5021).';
COMMENT ON COLUMN aeronave.id_modelo IS 'Modelo de la aeronave.';
COMMENT ON COLUMN aeronave.anio_fabricacion IS 'Año de fabricación.';
COMMENT ON COLUMN aeronave.horas_totales IS 'Horas totales de la célula según el último horómetro.';
COMMENT ON COLUMN aeronave.estado IS 'Estado operativo.';

-- Certificado de aeronavegabilidad vigente de cada aeronave.
CREATE TABLE cert_aeronavegabilidad (
    id_certificado INT NOT NULL,
    matricula VARCHAR(10) NOT NULL,
    numero_certificado VARCHAR(20) NOT NULL,
    fecha_expedicion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    CONSTRAINT pk_cert_aeronavegabilidad PRIMARY KEY (id_certificado),
    CONSTRAINT uq_cert_aeronavegabilidad_matricula UNIQUE (matricula),
    CONSTRAINT uq_cert_aeronavegabilidad_numero_certificado UNIQUE (numero_certificado),
    CONSTRAINT ck_cert_aeronavegabilidad_fecha_vencimiento CHECK (fecha_vencimiento > fecha_expedicion),
    CONSTRAINT fk_cert_aeronavegabilidad_matricula FOREIGN KEY (matricula) REFERENCES aeronave (matricula)
);
COMMENT ON TABLE cert_aeronavegabilidad IS 'Certificado de aeronavegabilidad vigente de cada aeronave.';
COMMENT ON COLUMN cert_aeronavegabilidad.id_certificado IS 'Identificador del certificado.';
COMMENT ON COLUMN cert_aeronavegabilidad.matricula IS 'Aeronave certificada.';
COMMENT ON COLUMN cert_aeronavegabilidad.numero_certificado IS 'Número del certificado.';
COMMENT ON COLUMN cert_aeronavegabilidad.fecha_expedicion IS 'Fecha de expedición.';
COMMENT ON COLUMN cert_aeronavegabilidad.fecha_vencimiento IS 'Fecha de vencimiento.';

-- Tabla asociativa con los modelos de aeronave en que está habilitado cada instructor.
CREATE TABLE habilitacion (
    id_instructor INT NOT NULL,
    id_modelo INT NOT NULL,
    fecha_habilitacion DATE NOT NULL,
    CONSTRAINT pk_habilitacion PRIMARY KEY (id_instructor, id_modelo),
    CONSTRAINT fk_habilitacion_id_instructor FOREIGN KEY (id_instructor) REFERENCES instructor (id_persona),
    CONSTRAINT fk_habilitacion_id_modelo FOREIGN KEY (id_modelo) REFERENCES modelo_aeronave (id_modelo)
);
COMMENT ON TABLE habilitacion IS 'Tabla asociativa con los modelos de aeronave en que está habilitado cada instructor.';
COMMENT ON COLUMN habilitacion.id_instructor IS 'Instructor habilitado.';
COMMENT ON COLUMN habilitacion.id_modelo IS 'Modelo para el cual está habilitado.';
COMMENT ON COLUMN habilitacion.fecha_habilitacion IS 'Fecha en que obtuvo la habilitación.';

-- Aeródromo desde o hacia el cual se realizan vuelos.
CREATE TABLE aerodromo (
    codigo_oaci CHAR(4) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    elevacion_ft INT NOT NULL,
    longitud_pista_m INT NOT NULL,
    CONSTRAINT pk_aerodromo PRIMARY KEY (codigo_oaci),
    CONSTRAINT ck_aerodromo_longitud_pista_m CHECK (longitud_pista_m > 0)
);
COMMENT ON TABLE aerodromo IS 'Aeródromo desde o hacia el cual se realizan vuelos.';
COMMENT ON COLUMN aerodromo.codigo_oaci IS 'Código OACI de cuatro letras (por ejemplo, SKBO).';
COMMENT ON COLUMN aerodromo.nombre IS 'Nombre del aeródromo.';
COMMENT ON COLUMN aerodromo.ciudad IS 'Ciudad o municipio donde se ubica.';
COMMENT ON COLUMN aerodromo.elevacion_ft IS 'Elevación en pies sobre el nivel del mar.';
COMMENT ON COLUMN aerodromo.longitud_pista_m IS 'Longitud de la pista principal en metros.';

-- Vuelo de instrucción programado o realizado.
CREATE TABLE vuelo (
    id_vuelo INT NOT NULL,
    fecha_vuelo DATE NOT NULL,
    hora_salida TIME NOT NULL,
    hora_llegada TIME,
    horometro_inicial DECIMAL(8,1),
    horometro_final DECIMAL(8,1),
    tipo_vuelo VARCHAR(10) NOT NULL,
    estado VARCHAR(10) NOT NULL,
    id_estudiante INT NOT NULL,
    id_instructor INT,
    matricula VARCHAR(10) NOT NULL,
    aerodromo_origen CHAR(4) NOT NULL,
    aerodromo_destino CHAR(4) NOT NULL,
    CONSTRAINT pk_vuelo PRIMARY KEY (id_vuelo),
    CONSTRAINT ck_vuelo_1 CHECK ((tipo_vuelo = 'SOLO' AND id_instructor IS NULL) OR (tipo_vuelo <> 'SOLO' AND id_instructor IS NOT NULL)),
    CONSTRAINT ck_vuelo_horometro_final CHECK (horometro_final > horometro_inicial),
    CONSTRAINT ck_vuelo_tipo_vuelo CHECK (tipo_vuelo IN ('LOCAL','NAVEGACION','SOLO','EXAMEN')),
    CONSTRAINT ck_vuelo_estado CHECK (estado IN ('PROGRAMADO','REALIZADO','CANCELADO')),
    CONSTRAINT fk_vuelo_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiante (id_persona),
    CONSTRAINT fk_vuelo_id_instructor FOREIGN KEY (id_instructor) REFERENCES instructor (id_persona),
    CONSTRAINT fk_vuelo_matricula FOREIGN KEY (matricula) REFERENCES aeronave (matricula),
    CONSTRAINT fk_vuelo_aerodromo_origen FOREIGN KEY (aerodromo_origen) REFERENCES aerodromo (codigo_oaci),
    CONSTRAINT fk_vuelo_aerodromo_destino FOREIGN KEY (aerodromo_destino) REFERENCES aerodromo (codigo_oaci)
);
COMMENT ON TABLE vuelo IS 'Vuelo de instrucción programado o realizado.';
COMMENT ON COLUMN vuelo.id_vuelo IS 'Identificador del vuelo.';
COMMENT ON COLUMN vuelo.fecha_vuelo IS 'Fecha del vuelo.';
COMMENT ON COLUMN vuelo.hora_salida IS 'Hora de salida.';
COMMENT ON COLUMN vuelo.hora_llegada IS 'Hora de llegada.';
COMMENT ON COLUMN vuelo.horometro_inicial IS 'Lectura del horómetro al iniciar.';
COMMENT ON COLUMN vuelo.horometro_final IS 'Lectura del horómetro al terminar.';
COMMENT ON COLUMN vuelo.tipo_vuelo IS 'Tipo de vuelo.';
COMMENT ON COLUMN vuelo.estado IS 'Estado del vuelo.';
COMMENT ON COLUMN vuelo.id_estudiante IS 'Estudiante que vuela.';
COMMENT ON COLUMN vuelo.id_instructor IS 'Instructor a bordo (nulo en vuelos solo).';
COMMENT ON COLUMN vuelo.matricula IS 'Aeronave utilizada.';
COMMENT ON COLUMN vuelo.aerodromo_origen IS 'Aeródromo de salida.';
COMMENT ON COLUMN vuelo.aerodromo_destino IS 'Aeródromo de llegada.';

-- Informe general del instructor sobre un vuelo realizado.
CREATE TABLE informe_vuelo (
    id_informe INT NOT NULL,
    id_vuelo INT NOT NULL,
    fecha_informe DATE NOT NULL,
    resultado VARCHAR(15) NOT NULL,
    observaciones VARCHAR(500),
    CONSTRAINT pk_informe_vuelo PRIMARY KEY (id_informe),
    CONSTRAINT uq_informe_vuelo_id_vuelo UNIQUE (id_vuelo),
    CONSTRAINT ck_informe_vuelo_resultado CHECK (resultado IN ('SATISFACTORIO','INSATISFACTORIO')),
    CONSTRAINT fk_informe_vuelo_id_vuelo FOREIGN KEY (id_vuelo) REFERENCES vuelo (id_vuelo)
);
COMMENT ON TABLE informe_vuelo IS 'Informe general del instructor sobre un vuelo realizado.';
COMMENT ON COLUMN informe_vuelo.id_informe IS 'Identificador del informe.';
COMMENT ON COLUMN informe_vuelo.id_vuelo IS 'Vuelo al que corresponde el informe.';
COMMENT ON COLUMN informe_vuelo.fecha_informe IS 'Fecha de elaboración del informe.';
COMMENT ON COLUMN informe_vuelo.resultado IS 'Resultado general del vuelo.';
COMMENT ON COLUMN informe_vuelo.observaciones IS 'Observaciones del instructor.';

-- Catálogo de maniobras evaluables durante la instrucción.
CREATE TABLE maniobra (
    id_maniobra INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    fase VARCHAR(15) NOT NULL,
    CONSTRAINT pk_maniobra PRIMARY KEY (id_maniobra),
    CONSTRAINT uq_maniobra_nombre UNIQUE (nombre),
    CONSTRAINT ck_maniobra_fase CHECK (fase IN ('PRESOLO','NAVEGACION','INSTRUMENTOS','AVANZADA'))
);
COMMENT ON TABLE maniobra IS 'Catálogo de maniobras evaluables durante la instrucción.';
COMMENT ON COLUMN maniobra.id_maniobra IS 'Identificador de la maniobra.';
COMMENT ON COLUMN maniobra.nombre IS 'Nombre de la maniobra.';
COMMENT ON COLUMN maniobra.fase IS 'Fase de instrucción a la que pertenece.';

-- Tabla asociativa con la calificación de cada maniobra ejecutada en un vuelo.
CREATE TABLE evaluacion_maniobra (
    id_vuelo INT NOT NULL,
    id_maniobra INT NOT NULL,
    calificacion SMALLINT NOT NULL,
    observacion VARCHAR(200),
    CONSTRAINT pk_evaluacion_maniobra PRIMARY KEY (id_vuelo, id_maniobra),
    CONSTRAINT ck_evaluacion_maniobra_calificacion CHECK (calificacion BETWEEN 1 AND 5),
    CONSTRAINT fk_evaluacion_maniobra_id_vuelo FOREIGN KEY (id_vuelo) REFERENCES vuelo (id_vuelo),
    CONSTRAINT fk_evaluacion_maniobra_id_maniobra FOREIGN KEY (id_maniobra) REFERENCES maniobra (id_maniobra)
);
COMMENT ON TABLE evaluacion_maniobra IS 'Tabla asociativa con la calificación de cada maniobra ejecutada en un vuelo.';
COMMENT ON COLUMN evaluacion_maniobra.id_vuelo IS 'Vuelo en el que se ejecutó la maniobra.';
COMMENT ON COLUMN evaluacion_maniobra.id_maniobra IS 'Maniobra evaluada.';
COMMENT ON COLUMN evaluacion_maniobra.calificacion IS 'Calificación en escala de 1 a 5.';
COMMENT ON COLUMN evaluacion_maniobra.observacion IS 'Comentario del instructor.';

-- Orden de mantenimiento ejecutada sobre una aeronave.
CREATE TABLE orden_trabajo (
    id_orden INT NOT NULL,
    matricula VARCHAR(10) NOT NULL,
    tipo_orden VARCHAR(15) NOT NULL,
    fecha_apertura DATE NOT NULL,
    fecha_cierre DATE,
    horas_aeronave DECIMAL(8,1) NOT NULL,
    descripcion VARCHAR(300) NOT NULL,
    CONSTRAINT pk_orden_trabajo PRIMARY KEY (id_orden),
    CONSTRAINT ck_orden_trabajo_tipo_orden CHECK (tipo_orden IN ('INSPECCION_50H','INSPECCION_100H','ANUAL','CORRECTIVA')),
    CONSTRAINT ck_orden_trabajo_fecha_cierre CHECK (fecha_cierre >= fecha_apertura),
    CONSTRAINT ck_orden_trabajo_horas_aeronave CHECK (horas_aeronave >= 0),
    CONSTRAINT fk_orden_trabajo_matricula FOREIGN KEY (matricula) REFERENCES aeronave (matricula)
);
COMMENT ON TABLE orden_trabajo IS 'Orden de mantenimiento ejecutada sobre una aeronave.';
COMMENT ON COLUMN orden_trabajo.id_orden IS 'Identificador de la orden de trabajo.';
COMMENT ON COLUMN orden_trabajo.matricula IS 'Aeronave intervenida.';
COMMENT ON COLUMN orden_trabajo.tipo_orden IS 'Tipo de mantenimiento.';
COMMENT ON COLUMN orden_trabajo.fecha_apertura IS 'Fecha de apertura.';
COMMENT ON COLUMN orden_trabajo.fecha_cierre IS 'Fecha de cierre (nula si está abierta).';
COMMENT ON COLUMN orden_trabajo.horas_aeronave IS 'Horas de la aeronave al abrir la orden.';
COMMENT ON COLUMN orden_trabajo.descripcion IS 'Descripción del trabajo.';

-- Tabla asociativa con los técnicos que trabajan en cada orden.
CREATE TABLE asignacion_tecnico (
    id_orden INT NOT NULL,
    id_tecnico INT NOT NULL,
    horas_trabajadas DECIMAL(5,1) NOT NULL,
    labor_realizada VARCHAR(200) NOT NULL,
    CONSTRAINT pk_asignacion_tecnico PRIMARY KEY (id_orden, id_tecnico),
    CONSTRAINT ck_asignacion_tecnico_horas_trabajadas CHECK (horas_trabajadas > 0),
    CONSTRAINT fk_asignacion_tecnico_id_orden FOREIGN KEY (id_orden) REFERENCES orden_trabajo (id_orden),
    CONSTRAINT fk_asignacion_tecnico_id_tecnico FOREIGN KEY (id_tecnico) REFERENCES tecnico (id_persona)
);
COMMENT ON TABLE asignacion_tecnico IS 'Tabla asociativa con los técnicos que trabajan en cada orden.';
COMMENT ON COLUMN asignacion_tecnico.id_orden IS 'Orden de trabajo.';
COMMENT ON COLUMN asignacion_tecnico.id_tecnico IS 'Técnico asignado.';
COMMENT ON COLUMN asignacion_tecnico.horas_trabajadas IS 'Horas invertidas por el técnico.';
COMMENT ON COLUMN asignacion_tecnico.labor_realizada IS 'Descripción de la labor realizada.';

-- Proveedor de repuestos aeronáuticos.
CREATE TABLE proveedor (
    id_proveedor INT NOT NULL,
    nit VARCHAR(15) NOT NULL,
    razon_social VARCHAR(100) NOT NULL,
    pais VARCHAR(40) NOT NULL,
    telefono VARCHAR(15),
    correo VARCHAR(100),
    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT uq_proveedor_nit UNIQUE (nit)
);
COMMENT ON TABLE proveedor IS 'Proveedor de repuestos aeronáuticos.';
COMMENT ON COLUMN proveedor.id_proveedor IS 'Identificador del proveedor.';
COMMENT ON COLUMN proveedor.nit IS 'NIT o identificación tributaria.';
COMMENT ON COLUMN proveedor.razon_social IS 'Razón social.';
COMMENT ON COLUMN proveedor.pais IS 'País del proveedor.';
COMMENT ON COLUMN proveedor.telefono IS 'Teléfono de contacto.';
COMMENT ON COLUMN proveedor.correo IS 'Correo electrónico.';

-- Catálogo de repuestos identificados por número de parte.
CREATE TABLE repuesto (
    numero_parte VARCHAR(30) NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    id_proveedor INT NOT NULL,
    CONSTRAINT pk_repuesto PRIMARY KEY (numero_parte),
    CONSTRAINT ck_repuesto_costo_unitario CHECK (costo_unitario > 0),
    CONSTRAINT fk_repuesto_id_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor)
);
COMMENT ON TABLE repuesto IS 'Catálogo de repuestos identificados por número de parte.';
COMMENT ON COLUMN repuesto.numero_parte IS 'Número de parte del fabricante.';
COMMENT ON COLUMN repuesto.descripcion IS 'Descripción del repuesto.';
COMMENT ON COLUMN repuesto.costo_unitario IS 'Costo unitario de referencia.';
COMMENT ON COLUMN repuesto.id_proveedor IS 'Proveedor del repuesto.';

-- Tabla asociativa con los repuestos instalados en cada orden de trabajo.
CREATE TABLE detalle_repuesto (
    id_orden INT NOT NULL,
    numero_parte VARCHAR(30) NOT NULL,
    cantidad SMALLINT NOT NULL,
    numero_serie VARCHAR(40),
    CONSTRAINT pk_detalle_repuesto PRIMARY KEY (id_orden, numero_parte),
    CONSTRAINT ck_detalle_repuesto_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_detalle_repuesto_id_orden FOREIGN KEY (id_orden) REFERENCES orden_trabajo (id_orden),
    CONSTRAINT fk_detalle_repuesto_numero_parte FOREIGN KEY (numero_parte) REFERENCES repuesto (numero_parte)
);
COMMENT ON TABLE detalle_repuesto IS 'Tabla asociativa con los repuestos instalados en cada orden de trabajo.';
COMMENT ON COLUMN detalle_repuesto.id_orden IS 'Orden de trabajo.';
COMMENT ON COLUMN detalle_repuesto.numero_parte IS 'Repuesto instalado.';
COMMENT ON COLUMN detalle_repuesto.cantidad IS 'Unidades instaladas.';
COMMENT ON COLUMN detalle_repuesto.numero_serie IS 'Número de serie de la pieza instalada, si aplica.';

-- Índices sobre llaves foráneas que no forman parte de la llave primaria (mejoran las reuniones)
CREATE INDEX ix_matricula_id_estudiante ON matricula (id_estudiante);
CREATE INDEX ix_matricula_id_programa ON matricula (id_programa);
CREATE INDEX ix_pago_id_matricula ON pago (id_matricula);
CREATE INDEX ix_modelo_aeronave_id_fabricante ON modelo_aeronave (id_fabricante);
CREATE INDEX ix_aeronave_id_modelo ON aeronave (id_modelo);
CREATE INDEX ix_vuelo_id_estudiante ON vuelo (id_estudiante);
CREATE INDEX ix_vuelo_id_instructor ON vuelo (id_instructor);
CREATE INDEX ix_vuelo_matricula ON vuelo (matricula);
CREATE INDEX ix_vuelo_aerodromo_origen ON vuelo (aerodromo_origen);
CREATE INDEX ix_vuelo_aerodromo_destino ON vuelo (aerodromo_destino);
CREATE INDEX ix_orden_trabajo_matricula ON orden_trabajo (matricula);
CREATE INDEX ix_repuesto_id_proveedor ON repuesto (id_proveedor);

COMMIT;
