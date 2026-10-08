-- ARSAVE seed data (demo admin)
-- Default credentials: admin@arsave.local / Admin@12345
-- Change immediately in production.

USE arsave;

INSERT INTO users (email, password_hash, name, role, kdf_salt)
VALUES (
  'admin@arsave.local',
  '$2y$10$TItH.M0FnSLbWonG/Z.dx.TgQncRB6krCwMayEzmJAUXohCEzA3sm',
  'Administrateur ARSAVE',
  'admin',
  UNHEX('0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef')
)
ON DUPLICATE KEY UPDATE
  password_hash = VALUES(password_hash),
  name = VALUES(name),
  role = VALUES(role);
