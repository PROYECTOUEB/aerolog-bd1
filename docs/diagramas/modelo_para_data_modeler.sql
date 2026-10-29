-- =====================================================================
-- AeroLog - Modelo relacional (Fase 1)
-- Script DDL de referencia para importar el modelo en MySQL Workbench
-- (File > Import > Reverse Engineer MySQL Create Script) o en
-- Oracle SQL Data Modeler (File > Import > DDL File).
-- La implementación física definitiva se realizará en la Fase 2.
-- =====================================================================

CREATE TABLE PERSONA (
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

CREATE TABLE ESTUDIANTE (
    id_persona INT NOT NULL,
    codigo_estudiante VARCHAR(10) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    CONSTRAINT pk_estudiante PRIMARY KEY (id_persona),
    CONSTRAINT uq_estudiante_codigo_estudiante UNIQUE (codigo_estudiante),
    CONSTRAINT fk_estudiante_id_persona FOREIGN KEY (id_persona) REFERENCES PERSONA (id_persona)
);

CREATE TABLE INSTRUCTOR (
    id_persona INT NOT NULL,
    numero_licencia VARCHAR(15) NOT NULL,
    fecha_venc_licencia DATE NOT NULL,
    CONSTRAINT pk_instructor PRIMARY KEY (id_persona),
    CONSTRAINT uq_instructor_numero_licencia UNIQUE (numero_licencia),
    CONSTRAINT fk_instructor_id_persona FOREIGN KEY (id_persona) REFERENCES PERSONA (id_persona)
);

CREATE TABLE TECNICO (
    id_persona INT NOT NULL,
    numero_licencia VARCHAR(15) NOT NULL,
    especialidad VARCHAR(15) NOT NULL,
    CONSTRAINT pk_tecnico PRIMARY KEY (id_persona),
    CONSTRAINT uq_tecnico_numero_licencia UNIQUE (numero_licencia),
    CONSTRAINT ck_tecnico_especialidad CHECK (especialidad IN ('MOTORES','AVIONICA','ESTRUCTURAS')),
    CONSTRAINT fk_tecnico_id_persona FOREIGN KEY (id_persona) REFERENCES PERSONA (id_persona)
);

CREATE TABLE CERTIFICADO_MEDICO (
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
    CONSTRAINT fk_certificado_medico_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES ESTUDIANTE (id_persona)
);

CREATE TABLE PROGRAMA (
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

CREATE TABLE CURSO (
    id_curso INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    intensidad_horaria SMALLINT NOT NULL,
    CONSTRAINT pk_curso PRIMARY KEY (id_curso),
    CONSTRAINT uq_curso_nombre UNIQUE (nombre),
    CONSTRAINT ck_curso_intensidad_horaria CHECK (intensidad_horaria > 0)
);

CREATE TABLE PLAN_ESTUDIOS (
    id_programa INT NOT NULL,
    id_curso INT NOT NULL,
    etapa SMALLINT NOT NULL,
    CONSTRAINT pk_plan_estudios PRIMARY KEY (id_programa, id_curso),
    CONSTRAINT ck_plan_estudios_etapa CHECK (etapa > 0),
    CONSTRAINT fk_plan_estudios_id_programa FOREIGN KEY (id_programa) REFERENCES PROGRAMA (id_programa),
    CONSTRAINT fk_plan_estudios_id_curso FOREIGN KEY (id_curso) REFERENCES CURSO (id_curso)
);

CREATE TABLE MATRICULA (
    id_matricula INT NOT NULL,
    id_estudiante INT NOT NULL,
    id_programa INT NOT NULL,
    fecha_matricula DATE NOT NULL,
    estado VARCHAR(12) NOT NULL,
    CONSTRAINT pk_matricula PRIMARY KEY (id_matricula),
    CONSTRAINT uq_matricula_1 UNIQUE (id_estudiante, id_programa, fecha_matricula),
    CONSTRAINT ck_matricula_estado CHECK (estado IN ('ACTIVA','SUSPENDIDA','FINALIZADA','RETIRADA')),
    CONSTRAINT fk_matricula_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES ESTUDIANTE (id_persona),
    CONSTRAINT fk_matricula_id_programa FOREIGN KEY (id_programa) REFERENCES PROGRAMA (id_programa)
);

CREATE TABLE CALIFICACION (
    id_estudiante INT NOT NULL,
    id_curso INT NOT NULL,
    nota_final DECIMAL(2,1) NOT NULL,
    fecha_calificacion DATE NOT NULL,
    CONSTRAINT pk_calificacion PRIMARY KEY (id_estudiante, id_curso),
    CONSTRAINT ck_calificacion_nota_final CHECK (nota_final BETWEEN 0 AND 5),
    CONSTRAINT fk_calificacion_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES ESTUDIANTE (id_persona),
    CONSTRAINT fk_calificacion_id_curso FOREIGN KEY (id_curso) REFERENCES CURSO (id_curso)
);

CREATE TABLE PAGO (
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
    CONSTRAINT fk_pago_id_matricula FOREIGN KEY (id_matricula) REFERENCES MATRICULA (id_matricula)
);

CREATE TABLE FABRICANTE (
    id_fabricante INT NOT NULL,
    nombre VARCHAR(60) NOT NULL,
    pais_origen VARCHAR(40) NOT NULL,
    CONSTRAINT pk_fabricante PRIMARY KEY (id_fabricante),
    CONSTRAINT uq_fabricante_nombre UNIQUE (nombre)
);

CREATE TABLE MODELO_AERONAVE (
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
    CONSTRAINT fk_modelo_aeronave_id_fabricante FOREIGN KEY (id_fabricante) REFERENCES FABRICANTE (id_fabricante)
);

CREATE TABLE AERONAVE (
    matricula VARCHAR(10) NOT NULL,
    id_modelo INT NOT NULL,
    anio_fabricacion SMALLINT NOT NULL,
    horas_totales DECIMAL(8,1) NOT NULL,
    estado VARCHAR(17) NOT NULL,
    CONSTRAINT pk_aeronave PRIMARY KEY (matricula),
    CONSTRAINT ck_aeronave_horas_totales CHECK (horas_totales >= 0),
    CONSTRAINT ck_aeronave_estado CHECK (estado IN ('DISPONIBLE','EN_MANTENIMIENTO','FUERA_DE_SERVICIO')),
    CONSTRAINT fk_aeronave_id_modelo FOREIGN KEY (id_modelo) REFERENCES MODELO_AERONAVE (id_modelo)
);

CREATE TABLE CERT_AERONAVEGABILIDAD (
    id_certificado INT NOT NULL,
    matricula VARCHAR(10) NOT NULL,
    numero_certificado VARCHAR(20) NOT NULL,
    fecha_expedicion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    CONSTRAINT pk_cert_aeronavegabilidad PRIMARY KEY (id_certificado),
    CONSTRAINT uq_cert_aeronavegabilidad_matricula UNIQUE (matricula),
    CONSTRAINT uq_cert_aeronavegabilidad_numero_certificado UNIQUE (numero_certificado),
    CONSTRAINT ck_cert_aeronavegabilidad_fecha_vencimiento CHECK (fecha_vencimiento > fecha_expedicion),
    CONSTRAINT fk_cert_aeronavegabilidad_matricula FOREIGN KEY (matricula) REFERENCES AERONAVE (matricula)
);

CREATE TABLE HABILITACION (
    id_instructor INT NOT NULL,
    id_modelo INT NOT NULL,
    fecha_habilitacion DATE NOT NULL,
    CONSTRAINT pk_habilitacion PRIMARY KEY (id_instructor, id_modelo),
    CONSTRAINT fk_habilitacion_id_instructor FOREIGN KEY (id_instructor) REFERENCES INSTRUCTOR (id_persona),
    CONSTRAINT fk_habilitacion_id_modelo FOREIGN KEY (id_modelo) REFERENCES MODELO_AERONAVE (id_modelo)
);

CREATE TABLE AERODROMO (
    codigo_oaci CHAR(4) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    elevacion_ft INT NOT NULL,
    longitud_pista_m INT NOT NULL,
    CONSTRAINT pk_aerodromo PRIMARY KEY (codigo_oaci),
    CONSTRAINT ck_aerodromo_longitud_pista_m CHECK (longitud_pista_m > 0)
);

CREATE TABLE VUELO (
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
    CONSTRAINT fk_vuelo_id_estudiante FOREIGN KEY (id_estudiante) REFERENCES ESTUDIANTE (id_persona),
    CONSTRAINT fk_vuelo_id_instructor FOREIGN KEY (id_instructor) REFERENCES INSTRUCTOR (id_persona),
    CONSTRAINT fk_vuelo_matricula FOREIGN KEY (matricula) REFERENCES AERONAVE (matricula),
    CONSTRAINT fk_vuelo_aerodromo_origen FOREIGN KEY (aerodromo_origen) REFERENCES AERODROMO (codigo_oaci),
    CONSTRAINT fk_vuelo_aerodromo_destino FOREIGN KEY (aerodromo_destino) REFERENCES AERODROMO (codigo_oaci)
);

CREATE TABLE INFORME_VUELO (
    id_informe INT NOT NULL,
    id_vuelo INT NOT NULL,
    fecha_informe DATE NOT NULL,
    resultado VARCHAR(15) NOT NULL,
    observaciones VARCHAR(500),
    CONSTRAINT pk_informe_vuelo PRIMARY KEY (id_informe),
    CONSTRAINT uq_informe_vuelo_id_vuelo UNIQUE (id_vuelo),
    CONSTRAINT ck_informe_vuelo_resultado CHECK (resultado IN ('SATISFACTORIO','INSATISFACTORIO')),
    CONSTRAINT fk_informe_vuelo_id_vuelo FOREIGN KEY (id_vuelo) REFERENCES VUELO (id_vuelo)
);

CREATE TABLE MANIOBRA (
    id_maniobra INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    fase VARCHAR(15) NOT NULL,
    CONSTRAINT pk_maniobra PRIMARY KEY (id_maniobra),
    CONSTRAINT uq_maniobra_nombre UNIQUE (nombre),
    CONSTRAINT ck_maniobra_fase CHECK (fase IN ('PRESOLO','NAVEGACION','INSTRUMENTOS','AVANZADA'))
);

CREATE TABLE EVALUACION_MANIOBRA (
    id_vuelo INT NOT NULL,
    id_maniobra INT NOT NULL,
    calificacion SMALLINT NOT NULL,
    observacion VARCHAR(200),
    CONSTRAINT pk_evaluacion_maniobra PRIMARY KEY (id_vuelo, id_maniobra),
    CONSTRAINT ck_evaluacion_maniobra_calificacion CHECK (calificacion BETWEEN 1 AND 5),
    CONSTRAINT fk_evaluacion_maniobra_id_vuelo FOREIGN KEY (id_vuelo) REFERENCES VUELO (id_vuelo),
    CONSTRAINT fk_evaluacion_maniobra_id_maniobra FOREIGN KEY (id_maniobra) REFERENCES MANIOBRA (id_maniobra)
);

CREATE TABLE ORDEN_TRABAJO (
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
    CONSTRAINT fk_orden_trabajo_matricula FOREIGN KEY (matricula) REFERENCES AERONAVE (matricula)
);

CREATE TABLE ASIGNACION_TECNICO (
    id_orden INT NOT NULL,
    id_tecnico INT NOT NULL,
    horas_trabajadas DECIMAL(5,1) NOT NULL,
    labor_realizada VARCHAR(200) NOT NULL,
    CONSTRAINT pk_asignacion_tecnico PRIMARY KEY (id_orden, id_tecnico),
    CONSTRAINT ck_asignacion_tecnico_horas_trabajadas CHECK (horas_trabajadas > 0),
    CONSTRAINT fk_asignacion_tecnico_id_orden FOREIGN KEY (id_orden) REFERENCES ORDEN_TRABAJO (id_orden),
    CONSTRAINT fk_asignacion_tecnico_id_tecnico FOREIGN KEY (id_tecnico) REFERENCES TECNICO (id_persona)
);

CREATE TABLE PROVEEDOR (
    id_proveedor INT NOT NULL,
    nit VARCHAR(15) NOT NULL,
    razon_social VARCHAR(100) NOT NULL,
    pais VARCHAR(40) NOT NULL,
    telefono VARCHAR(15),
    correo VARCHAR(100),
    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT uq_proveedor_nit UNIQUE (nit)
);

CREATE TABLE REPUESTO (
    numero_parte VARCHAR(30) NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    id_proveedor INT NOT NULL,
    CONSTRAINT pk_repuesto PRIMARY KEY (numero_parte),
    CONSTRAINT ck_repuesto_costo_unitario CHECK (costo_unitario > 0),
    CONSTRAINT fk_repuesto_id_proveedor FOREIGN KEY (id_proveedor) REFERENCES PROVEEDOR (id_proveedor)
);

CREATE TABLE DETALLE_REPUESTO (
    id_orden INT NOT NULL,
    numero_parte VARCHAR(30) NOT NULL,
    cantidad SMALLINT NOT NULL,
    numero_serie VARCHAR(40),
    CONSTRAINT pk_detalle_repuesto PRIMARY KEY (id_orden, numero_parte),
    CONSTRAINT ck_detalle_repuesto_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_detalle_repuesto_id_orden FOREIGN KEY (id_orden) REFERENCES ORDEN_TRABAJO (id_orden),
    CONSTRAINT fk_detalle_repuesto_numero_parte FOREIGN KEY (numero_parte) REFERENCES REPUESTO (numero_parte)
);
