-- AeroLog - Sentencias SQL equivalentes a los ejercicios de álgebra relacional

-- Ejercicio 1. ¿Cuáles son la matrícula, el año de fabricación y las horas totales de las aeronaves que se encuentran disponibles para volar?
SELECT matricula, anio_fabricacion, horas_totales FROM AERONAVE WHERE estado = 'DISPONIBLE';

-- Ejercicio 2. ¿Qué modelos de aeronave de la flota son bimotores y cuántos asientos tienen?
SELECT nombre, capacidad_asientos FROM MODELO_AERONAVE WHERE numero_motores = 2;

-- Ejercicio 3. ¿Qué vuelos de navegación ya fueron realizados y entre qué aeródromos?
SELECT id_vuelo, fecha_vuelo, aerodromo_origen, aerodromo_destino FROM VUELO WHERE tipo_vuelo = 'NAVEGACION' AND estado = 'REALIZADO';

-- Ejercicio 4. ¿Qué vuelos están programados, con su fecha, hora de salida y aeronave asignada?
SELECT id_vuelo, fecha_vuelo, hora_salida, matricula FROM VUELO WHERE estado = 'PROGRAMADO';

-- Ejercicio 5. ¿Qué aeródromos tienen una pista principal de al menos 2 000 metros?
SELECT codigo_oaci, nombre, ciudad FROM AERODROMO WHERE longitud_pista_m >= 2000;

-- Ejercicio 6. ¿Qué pagos superiores a $10 000 000 se realizaron por transferencia?
SELECT id_pago, id_matricula, fecha_pago, valor FROM PAGO WHERE valor > 10000000 AND medio_pago = 'TRANSFERENCIA';

-- Ejercicio 7. ¿Qué órdenes de trabajo de mantenimiento siguen abiertas?
SELECT id_orden, matricula, tipo_orden, fecha_apertura FROM ORDEN_TRABAJO WHERE fecha_cierre IS NULL;

-- Ejercicio 8. ¿Qué maniobras pertenecen a las fases de instrumentos o avanzada?
SELECT id_maniobra, nombre, fase FROM MANIOBRA WHERE fase = 'INSTRUMENTOS' OR fase = 'AVANZADA';

-- Ejercicio 9. ¿Qué notas finales registradas son reprobatorias (menores a 3,0)?
SELECT id_estudiante, id_curso, nota_final FROM CALIFICACION WHERE nota_final < 3.0;

-- Ejercicio 10. ¿Qué tipos de órdenes de trabajo se han registrado en la escuela?
SELECT DISTINCT tipo_orden FROM ORDEN_TRABAJO;

-- Ejercicio 11. ¿Qué fabricante produce cada uno de los modelos de la flota? (resuelta con producto cartesiano)
SELECT M.nombre AS modelo, F.nombre AS fabricante FROM MODELO_AERONAVE M, FABRICANTE F WHERE M.id_fabricante = F.id_fabricante;

-- Ejercicio 12. ¿Cuál es el modelo y el fabricante de cada aeronave de la flota? (resuelta con reunión theta)
SELECT A.matricula, M.nombre AS modelo, F.nombre AS fabricante
FROM AERONAVE A JOIN MODELO_AERONAVE M ON A.id_modelo = M.id_modelo
JOIN FABRICANTE F ON M.id_fabricante = F.id_fabricante;

-- Ejercicio 13. ¿Cuáles son el código, los nombres y los apellidos de todos los estudiantes?
SELECT E.codigo_estudiante, P.nombres, P.apellidos FROM ESTUDIANTE E NATURAL JOIN PERSONA P;

-- Ejercicio 14. ¿Qué instructores tienen una licencia que vence antes del 1 de enero de 2027?
SELECT P.nombres, P.apellidos, I.numero_licencia, I.fecha_venc_licencia FROM INSTRUCTOR I NATURAL JOIN PERSONA P WHERE I.fecha_venc_licencia < '2027-01-01';

-- Ejercicio 15. ¿Cuáles son los nombres y licencias de los técnicos especializados en aviónica?
SELECT P.nombres, P.apellidos, T.numero_licencia FROM TECNICO T NATURAL JOIN PERSONA P WHERE T.especialidad = 'AVIONICA';

-- Ejercicio 16. ¿Qué cursos componen el programa de Piloto Comercial de Avión y en qué etapa se dictan?
SELECT C.nombre, PE.etapa FROM PROGRAMA P JOIN PLAN_ESTUDIOS PE ON P.id_programa = PE.id_programa
JOIN CURSO C ON PE.id_curso = C.id_curso WHERE P.nombre = 'Piloto Comercial de Avión';

-- Ejercicio 17. ¿Qué vuelos ha realizado el estudiante con código E-0003, en qué fecha y en qué aeronave?
SELECT V.id_vuelo, V.fecha_vuelo, V.tipo_vuelo, V.matricula FROM ESTUDIANTE E JOIN VUELO V ON E.id_persona = V.id_estudiante
WHERE E.codigo_estudiante = 'E-0003' AND V.estado = 'REALIZADO';

-- Ejercicio 18. ¿A qué aeródromo y ciudad se dirigió cada vuelo de navegación realizado?
SELECT V.id_vuelo, V.fecha_vuelo, A.nombre, A.ciudad FROM VUELO V JOIN AERODROMO A ON V.aerodromo_destino = A.codigo_oaci
WHERE V.tipo_vuelo = 'NAVEGACION' AND V.estado = 'REALIZADO';

-- Ejercicio 19. ¿En qué programa está matriculado actualmente cada estudiante con matrícula activa?
SELECT P.nombres, P.apellidos, PR.nombre AS programa FROM MATRICULA M JOIN PERSONA P ON M.id_estudiante = P.id_persona
JOIN PROGRAMA PR ON M.id_programa = PR.id_programa WHERE M.estado = 'ACTIVA';

-- Ejercicio 20. ¿Qué repuestos se han instalado en la aeronave HK-5021 y quién es su proveedor?
SELECT O.id_orden, R.numero_parte, R.descripcion, D.cantidad, PV.razon_social FROM ORDEN_TRABAJO O
JOIN DETALLE_REPUESTO D ON O.id_orden = D.id_orden JOIN REPUESTO R ON D.numero_parte = R.numero_parte
JOIN PROVEEDOR PV ON R.id_proveedor = PV.id_proveedor WHERE O.matricula = 'HK-5021';

-- Ejercicio 21. ¿Qué técnicos trabajaron en órdenes de inspección anual y cuántas horas dedicaron?
SELECT O.id_orden, O.matricula, P.nombres, P.apellidos, A.horas_trabajadas FROM ORDEN_TRABAJO O
JOIN ASIGNACION_TECNICO A ON O.id_orden = A.id_orden JOIN PERSONA P ON A.id_tecnico = P.id_persona WHERE O.tipo_orden = 'ANUAL';

-- Ejercicio 22. ¿Qué maniobras se evaluaron en el vuelo 1001 y qué calificación obtuvo el estudiante en cada una?
SELECT M.nombre, M.fase, E.calificacion FROM EVALUACION_MANIOBRA E NATURAL JOIN MANIOBRA M WHERE E.id_vuelo = 1001;

-- Ejercicio 23. ¿Qué instructores están habilitados para volar el modelo DA42-VI?
SELECT P.nombres, P.apellidos, H.fecha_habilitacion FROM MODELO_AERONAVE M JOIN HABILITACION H ON M.id_modelo = H.id_modelo
JOIN PERSONA P ON H.id_instructor = P.id_persona WHERE M.nombre = 'DA42-VI';

-- Ejercicio 24. ¿Qué vuelos tuvieron un informe con resultado insatisfactorio y qué estudiante los realizó?
SELECT V.id_vuelo, V.fecha_vuelo, E.codigo_estudiante FROM INFORME_VUELO I JOIN VUELO V ON I.id_vuelo = V.id_vuelo
JOIN ESTUDIANTE E ON V.id_estudiante = E.id_persona WHERE I.resultado = 'INSATISFACTORIO';

-- Ejercicio 25. Para cada vuelo de navegación realizado, ¿cuál es el nombre del aeródromo de origen y el del aeródromo de destino?
SELECT V.id_vuelo, O.nombre AS origen, D.nombre AS destino FROM VUELO V
JOIN AERODROMO O ON V.aerodromo_origen = O.codigo_oaci JOIN AERODROMO D ON V.aerodromo_destino = D.codigo_oaci
WHERE V.tipo_vuelo = 'NAVEGACION' AND V.estado = 'REALIZADO';

-- Ejercicio 26. ¿Cuál es el nombre del estudiante y el nombre del instructor de cada vuelo de examen?
SELECT V.id_vuelo, V.fecha_vuelo, PE.nombres || ' ' || PE.apellidos AS estudiante, PI.nombres || ' ' || PI.apellidos AS instructor
FROM VUELO V JOIN PERSONA PE ON V.id_estudiante = PE.id_persona JOIN PERSONA PI ON V.id_instructor = PI.id_persona
WHERE V.tipo_vuelo = 'EXAMEN';

-- Ejercicio 27. ¿Qué pares de aeronaves de la flota pertenecen al mismo modelo?
SELECT A1.matricula, A2.matricula FROM AERONAVE A1 JOIN AERONAVE A2
ON A1.id_modelo = A2.id_modelo AND A1.matricula < A2.matricula;

-- Ejercicio 28. ¿Qué vuelos de navegación llegaron a un aeródromo de menor elevación que la del aeródromo de origen?
SELECT V.id_vuelo, O.codigo_oaci, O.elevacion_ft, D.codigo_oaci, D.elevacion_ft FROM VUELO V
JOIN AERODROMO O ON V.aerodromo_origen = O.codigo_oaci JOIN AERODROMO D ON V.aerodromo_destino = D.codigo_oaci
WHERE V.tipo_vuelo = 'NAVEGACION' AND D.elevacion_ft < O.elevacion_ft;

-- Ejercicio 29. ¿Qué pares de modelos de aeronave son producidos por el mismo fabricante?
SELECT M1.nombre, M2.nombre FROM MODELO_AERONAVE M1 JOIN MODELO_AERONAVE M2
ON M1.id_fabricante = M2.id_fabricante AND M1.id_modelo < M2.id_modelo;

-- Ejercicio 30. ¿Qué personas trabajan en la escuela como instructores o como técnicos?
SELECT P.id_persona, P.nombres, P.apellidos FROM PERSONA P
WHERE P.id_persona IN (SELECT id_persona FROM INSTRUCTOR UNION SELECT id_persona FROM TECNICO);

-- Ejercicio 31. ¿Qué personas son al mismo tiempo instructores y estudiantes?
SELECT P.id_persona, P.nombres, P.apellidos FROM PERSONA P
WHERE P.id_persona IN (SELECT id_persona FROM INSTRUCTOR INTERSECT SELECT id_persona FROM ESTUDIANTE);

-- Ejercicio 32. ¿Qué instructores también son técnicos de mantenimiento?
SELECT P.nombres, P.apellidos FROM PERSONA P
WHERE P.id_persona IN (SELECT id_persona FROM INSTRUCTOR INTERSECT SELECT id_persona FROM TECNICO);

-- Ejercicio 33. ¿Qué estudiantes nunca han realizado un vuelo solo?
SELECT E.codigo_estudiante, P.nombres, P.apellidos FROM ESTUDIANTE E NATURAL JOIN PERSONA P
WHERE E.id_persona IN (SELECT id_persona FROM ESTUDIANTE
  EXCEPT SELECT id_estudiante FROM VUELO WHERE tipo_vuelo = 'SOLO' AND estado = 'REALIZADO');

-- Ejercicio 34. ¿Qué estudiantes no tienen certificado médico registrado?
SELECT codigo_estudiante FROM ESTUDIANTE WHERE id_persona IN
(SELECT id_persona FROM ESTUDIANTE EXCEPT SELECT id_estudiante FROM CERTIFICADO_MEDICO);

-- Ejercicio 35. ¿Qué repuestos del catálogo nunca se han instalado en una orden de trabajo?
SELECT numero_parte, descripcion FROM REPUESTO WHERE numero_parte IN
(SELECT numero_parte FROM REPUESTO EXCEPT SELECT numero_parte FROM DETALLE_REPUESTO);

-- Ejercicio 36. ¿Qué aeródromos nunca han sido destino de un vuelo de navegación?
SELECT codigo_oaci FROM AERODROMO EXCEPT SELECT aerodromo_destino FROM VUELO WHERE tipo_vuelo = 'NAVEGACION';

-- Ejercicio 37. ¿Qué aeródromos han sido utilizados como origen o como destino de algún vuelo?
SELECT aerodromo_origen AS codigo_oaci FROM VUELO UNION SELECT aerodromo_destino FROM VUELO;

-- Ejercicio 38. ¿Qué estudiantes se han matriculado tanto en el programa de Piloto Privado como en el de Piloto Comercial?
SELECT id_estudiante FROM MATRICULA WHERE id_programa = 1 INTERSECT SELECT id_estudiante FROM MATRICULA WHERE id_programa = 2;

-- Ejercicio 39. ¿Qué estudiantes matriculados en Piloto Privado aún no se han matriculado en Piloto Comercial?
SELECT id_estudiante FROM MATRICULA WHERE id_programa = 1 EXCEPT SELECT id_estudiante FROM MATRICULA WHERE id_programa = 2;

-- Ejercicio 40. ¿Qué aeronaves no son aptas para programar vuelos, ya sea por su estado o por tener el certificado de aeronavegabilidad vencido?
SELECT matricula FROM AERONAVE WHERE estado <> 'DISPONIBLE'
UNION SELECT matricula FROM CERT_AERONAVEGABILIDAD WHERE fecha_vencimiento < CURRENT_DATE;

-- Ejercicio 41. ¿Qué aeronaves no tienen certificado de aeronavegabilidad registrado?
SELECT matricula FROM AERONAVE EXCEPT SELECT matricula FROM CERT_AERONAVEGABILIDAD;

-- Ejercicio 42. ¿Qué instructores están habilitados en todos los modelos bimotores de la flota?
SELECT P.nombres, P.apellidos FROM PERSONA P JOIN INSTRUCTOR I ON P.id_persona = I.id_persona
WHERE NOT EXISTS (SELECT 1 FROM MODELO_AERONAVE M WHERE M.numero_motores = 2
  AND NOT EXISTS (SELECT 1 FROM HABILITACION H WHERE H.id_instructor = I.id_persona AND H.id_modelo = M.id_modelo));

-- Ejercicio 43. ¿Qué estudiantes aprobaron todos los cursos del programa de Piloto Privado?
SELECT E.codigo_estudiante FROM ESTUDIANTE E WHERE NOT EXISTS (
  SELECT 1 FROM PLAN_ESTUDIOS PE WHERE PE.id_programa = 1 AND NOT EXISTS (
    SELECT 1 FROM CALIFICACION C WHERE C.id_estudiante = E.id_persona AND C.id_curso = PE.id_curso AND C.nota_final >= 3.0));

-- Ejercicio 44. ¿Qué instructores están habilitados en todos los modelos fabricados por Cessna Aircraft?
SELECT I.id_persona FROM INSTRUCTOR I WHERE NOT EXISTS (
  SELECT 1 FROM MODELO_AERONAVE M JOIN FABRICANTE F ON M.id_fabricante = F.id_fabricante
  WHERE F.nombre = 'Cessna Aircraft' AND NOT EXISTS (
    SELECT 1 FROM HABILITACION H WHERE H.id_instructor = I.id_persona AND H.id_modelo = M.id_modelo));

-- Ejercicio 45. ¿Qué estudiantes han sido evaluados en todas las maniobras de la fase PRESOLO?
SELECT E.id_persona FROM ESTUDIANTE E WHERE NOT EXISTS (
  SELECT 1 FROM MANIOBRA M WHERE M.fase = 'PRESOLO' AND NOT EXISTS (
    SELECT 1 FROM VUELO V JOIN EVALUACION_MANIOBRA EM ON V.id_vuelo = EM.id_vuelo
    WHERE V.id_estudiante = E.id_persona AND EM.id_maniobra = M.id_maniobra));

-- Ejercicio 46. ¿Qué técnicos han participado en órdenes de trabajo de todos los tipos registrados (inspecciones de 50 y 100 horas, anual y correctiva)?
SELECT P.nombres, P.apellidos FROM TECNICO T JOIN PERSONA P ON T.id_persona = P.id_persona WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT DISTINCT tipo_orden FROM ORDEN_TRABAJO) X WHERE NOT EXISTS (
    SELECT 1 FROM ASIGNACION_TECNICO A JOIN ORDEN_TRABAJO O ON A.id_orden = O.id_orden
    WHERE A.id_tecnico = T.id_persona AND O.tipo_orden = X.tipo_orden));

-- Ejercicio 47. ¿Cuántos vuelos ha realizado cada estudiante?
SELECT id_estudiante, COUNT(id_vuelo) AS total_vuelos FROM VUELO WHERE estado = 'REALIZADO' GROUP BY id_estudiante;

-- Ejercicio 48. ¿Cuántas horas de vuelo ha acumulado cada estudiante?
SELECT id_estudiante, ROUND(SUM(horometro_final - horometro_inicial), 1) AS horas_acumuladas
FROM VUELO WHERE estado = 'REALIZADO' GROUP BY id_estudiante;

-- Ejercicio 49. ¿Cuál es el promedio de las notas finales de cada curso teórico?
SELECT C.nombre, ROUND(AVG(CA.nota_final), 2) AS promedio FROM CALIFICACION CA JOIN CURSO C ON CA.id_curso = C.id_curso GROUP BY C.nombre;

-- Ejercicio 50. ¿Cuánto ha pagado en total cada estudiante por cada una de sus matrículas?
SELECT M.id_estudiante, M.id_matricula, SUM(P.valor) AS total_pagado FROM MATRICULA M JOIN PAGO P ON M.id_matricula = P.id_matricula
GROUP BY M.id_estudiante, M.id_matricula;

-- Ejercicio 51. ¿Cuántas horas de mantenimiento ha trabajado cada técnico?
SELECT id_tecnico, SUM(horas_trabajadas) AS horas, COUNT(id_orden) AS ordenes FROM ASIGNACION_TECNICO GROUP BY id_tecnico;

-- Ejercicio 52. ¿Cuál es el costo total de los repuestos instalados en cada orden de trabajo?
SELECT D.id_orden, SUM(D.cantidad * R.costo_unitario) AS costo_repuestos FROM DETALLE_REPUESTO D
JOIN REPUESTO R ON D.numero_parte = R.numero_parte GROUP BY D.id_orden;

-- Ejercicio 53. ¿Cuántas aeronaves de la flota tiene cada fabricante?
SELECT F.nombre, COUNT(A.matricula) AS cantidad FROM AERONAVE A JOIN MODELO_AERONAVE M ON A.id_modelo = M.id_modelo
JOIN FABRICANTE F ON M.id_fabricante = F.id_fabricante GROUP BY F.nombre;

-- Ejercicio 54. ¿Cuántos vuelos se han realizado de cada tipo y cuál es su duración promedio?
SELECT tipo_vuelo, COUNT(*) AS vuelos, ROUND(AVG(horometro_final - horometro_inicial), 2) AS duracion_promedio
FROM VUELO WHERE estado = 'REALIZADO' GROUP BY tipo_vuelo;

-- Ejercicio 55. ¿Qué maniobras tienen una calificación promedio inferior a 3,5?
SELECT M.nombre, ROUND(AVG(E.calificacion), 2) AS promedio FROM EVALUACION_MANIOBRA E JOIN MANIOBRA M ON E.id_maniobra = M.id_maniobra
GROUP BY M.nombre HAVING AVG(E.calificacion) < 3.5;

-- Ejercicio 56. ¿Cuántos estudiantes hay matriculados en cada programa según el estado de la matrícula?
SELECT P.nombre, M.estado, COUNT(M.id_estudiante) AS total FROM MATRICULA M JOIN PROGRAMA P ON M.id_programa = P.id_programa
GROUP BY P.nombre, M.estado;

-- Ejercicio 57. ¿Cuál es el número y la fecha de vencimiento del certificado de aeronavegabilidad de cada aeronave, incluidas las que no tienen certificado?
SELECT A.matricula, C.numero_certificado, C.fecha_vencimiento FROM AERONAVE A LEFT JOIN CERT_AERONAVEGABILIDAD C ON A.matricula = C.matricula;

-- Ejercicio 58. ¿Cuál es la fecha de vencimiento del certificado médico de cada estudiante, incluidos los que no lo tienen?
SELECT E.codigo_estudiante, C.numero_certificado, C.fecha_vencimiento FROM ESTUDIANTE E
LEFT JOIN CERTIFICADO_MEDICO C ON E.id_persona = C.id_estudiante;

-- Ejercicio 59. ¿Cuántas unidades se han instalado de cada repuesto del catálogo, incluidos los que nunca se han instalado?
SELECT R.numero_parte, SUM(D.cantidad) AS unidades FROM REPUESTO R LEFT JOIN DETALLE_REPUESTO D ON R.numero_parte = D.numero_parte
GROUP BY R.numero_parte;

-- Ejercicio 60. ¿Qué estudiantes con matrícula activa tienen el certificado médico vencido?
SELECT P.nombres, P.apellidos, P.correo FROM PERSONA P WHERE P.id_persona IN (
  SELECT id_estudiante FROM MATRICULA WHERE estado = 'ACTIVA'
  INTERSECT SELECT id_estudiante FROM CERTIFICADO_MEDICO WHERE fecha_vencimiento < CURRENT_DATE);

-- Ejercicio 61. ¿Existe algún vuelo en el que el instructor no estuviera habilitado en el modelo de la aeronave utilizada?
SELECT DISTINCT V.id_instructor, A.id_modelo FROM VUELO V JOIN AERONAVE A ON V.matricula = A.matricula WHERE V.id_instructor IS NOT NULL
EXCEPT SELECT id_instructor, id_modelo FROM HABILITACION;

-- Ejercicio 62. ¿Qué porcentaje de las horas mínimas de vuelo exigidas ha completado cada estudiante con matrícula activa?
SELECT M.id_estudiante, P.nombre, ROUND(H.horas, 1) AS horas, ROUND(H.horas * 100 / P.horas_minimas_vuelo, 1) AS porcentaje_avance
FROM MATRICULA M JOIN (SELECT id_estudiante, SUM(horometro_final - horometro_inicial) AS horas FROM VUELO
  WHERE estado = 'REALIZADO' GROUP BY id_estudiante) H ON M.id_estudiante = H.id_estudiante
JOIN PROGRAMA P ON M.id_programa = P.id_programa WHERE M.estado = 'ACTIVA';

-- Ejercicio 63. ¿Cuál es la aeronave que más horas ha volado en los vuelos registrados?
WITH H AS (SELECT matricula, SUM(horometro_final - horometro_inicial) AS horas FROM VUELO WHERE estado = 'REALIZADO' GROUP BY matricula)
SELECT matricula, ROUND(horas, 1) AS horas FROM H WHERE horas = (SELECT MAX(horas) FROM H);

-- Ejercicio 64. ¿Qué instructores han impartido vuelos en más de un modelo de aeronave distinto?
SELECT P.nombres, P.apellidos, COUNT(DISTINCT A.id_modelo) AS modelos FROM VUELO V JOIN AERONAVE A ON V.matricula = A.matricula
JOIN PERSONA P ON V.id_instructor = P.id_persona GROUP BY P.id_persona, P.nombres, P.apellidos HAVING COUNT(DISTINCT A.id_modelo) > 1;

-- Ejercicio 65. ¿Qué aeronaves tuvieron órdenes de mantenimiento correctivo y en cuántas ocasiones?
SELECT matricula, COUNT(id_orden) AS correctivos FROM ORDEN_TRABAJO WHERE tipo_orden = 'CORRECTIVA' GROUP BY matricula;
