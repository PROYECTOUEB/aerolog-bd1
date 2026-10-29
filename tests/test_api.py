"""Pruebas de la API de AeroLog contra la base de datos configurada en .env.

Ejecutar desde la raíz del proyecto:  python -m unittest -v
"""
import unittest

from app import create_app


class PruebasAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.c = create_app({'TESTING': True}).test_client()

    def get(self, url, codigo=200):
        r = self.c.get(url)
        self.assertEqual(r.status_code, codigo, f'{url}: {r.get_data(as_text=True)[:300]}')
        return r.get_json()

    def test_estado_conexion(self):
        d = self.get('/api/estado')
        self.assertEqual(d['conexion'], 'ok')
        self.assertEqual(d['tablas'], 26)

    def test_panel(self):
        d = self.get('/api/panel')
        for clave in ('kpi', 'alertas', 'horas_aeronave', 'por_tipo', 'por_mes', 'proximos'):
            self.assertIn(clave, d)
        self.assertGreater(d['kpi']['vuelos_realizados'], 0)

    def test_estudiantes_y_detalle(self):
        lista = self.get('/api/estudiantes')
        self.assertGreater(len(lista), 0)
        d = self.get(f"/api/estudiantes/{lista[0]['id_persona']}")
        self.assertEqual(d['datos']['codigo_estudiante'], lista[0]['codigo_estudiante'])

    def test_busqueda_sin_tildes(self):
        con_tilde = self.get('/api/estudiantes?q=gómez')
        sin_tilde = self.get('/api/estudiantes?q=gomez')
        self.assertEqual(len(con_tilde), len(sin_tilde))

    def test_flota_y_detalle(self):
        lista = self.get('/api/aeronaves')
        self.get(f"/api/aeronaves/{lista[0]['matricula']}")

    def test_vuelos_con_filtros(self):
        todos = self.get('/api/vuelos')
        realizados = self.get('/api/vuelos?estado=REALIZADO')
        self.assertTrue(all(v['estado'] == 'REALIZADO' for v in realizados))
        self.assertLessEqual(len(realizados), len(todos))
        self.get(f"/api/vuelos/{todos[0]['id_vuelo']}")

    def test_mantenimiento(self):
        lista = self.get('/api/mantenimiento')
        self.get(f"/api/mantenimiento/{lista[0]['id_orden']}")
        abiertas = self.get('/api/mantenimiento?estado=abiertas')
        self.assertTrue(all(o['estado'] == 'ABIERTA' for o in abiertas))

    def test_instructores_y_academico(self):
        self.assertGreater(len(self.get('/api/instructores')), 0)
        self.assertGreater(len(self.get('/api/academico')), 0)

    def test_todas_las_consultas_de_algebra(self):
        lista = self.get('/api/consultas')
        self.assertGreaterEqual(len(lista), 50)
        for c in lista:
            d = self.get(f"/api/consultas/{c['n']}")
            self.assertEqual(len(d['filas']), d['total'])

    def test_errores(self):
        self.get('/api/estudiantes/999999', 404)
        self.get('/api/vuelos?tipo=NO_EXISTE', 400)
        self.get('/api/consultas/0', 404)


if __name__ == '__main__':
    unittest.main()
