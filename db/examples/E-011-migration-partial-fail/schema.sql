USE db_e_E_011_migration_partial_fail;
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(20) NOT NULL
) ENGINE=InnoDB;
INSERT INTO users (name) VALUES ('seed-a'), ('seed-b');
CREATE TABLE schema_migrations (
  version INT PRIMARY KEY,
  name VARCHAR(50) NOT NULL
) ENGINE=InnoDB;
INSERT INTO schema_migrations (version, name) VALUES (1, 'init');
