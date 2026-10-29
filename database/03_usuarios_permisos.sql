-- =====================================================================
-- AeroLog - Script de usuarios y permisos
-- RDBMS: PostgreSQL 18 | Base de datos: aerolog
-- Generado: 2026-10-28
-- =====================================================================

-- Ejecutar como superusuario (postgres) conectado a la base de datos aerolog.
-- Cambie las contraseñas antes de ejecutar el script.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aerolog_admin') THEN
    CREATE ROLE aerolog_admin LOGIN PASSWORD 'Cambiar_Admin_2026';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aerolog_app') THEN
    CREATE ROLE aerolog_app LOGIN PASSWORD 'Cambiar_App_2026';
  END IF;
END $$;

-- El administrador es propietario de la base de datos y de sus objetos
ALTER DATABASE aerolog OWNER TO aerolog_admin;
GRANT ALL ON SCHEMA public TO aerolog_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public TO aerolog_admin;

-- La aplicación web solo puede leer (principio de mínimo privilegio)
GRANT CONNECT ON DATABASE aerolog TO aerolog_app;
GRANT USAGE ON SCHEMA public TO aerolog_app;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO aerolog_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO aerolog_app;
ALTER ROLE aerolog_app SET default_transaction_read_only = on;
