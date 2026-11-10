USE db_e_E_005_isolation_lost_update;
CREATE TABLE counters (
  name VARCHAR(32) PRIMARY KEY,
  value INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO counters VALUES ('hits', 100);
