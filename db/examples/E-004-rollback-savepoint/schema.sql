USE db_e_E_004_rollback_savepoint;
CREATE TABLE tags (
  id INT PRIMARY KEY,
  label VARCHAR(16) NOT NULL UNIQUE
) ENGINE=InnoDB;
