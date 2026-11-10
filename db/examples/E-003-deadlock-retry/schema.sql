USE db_e_E_003_deadlock_retry;
CREATE TABLE accounts (
  id INT PRIMARY KEY,
  balance INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO accounts VALUES (1, 100), (2, 100), (3, 100);
