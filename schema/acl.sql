BEGIN;

GRANT SELECT
   ON ALL TABLES IN SCHEMA public
   TO :ro_role;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
   ON ALL TABLES IN SCHEMA public
   TO :rw_role;

COMMIT;
