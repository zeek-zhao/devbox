USE db_e_E_015_antipattern_swallow;
CREATE TABLE wallets (
  id INT PRIMARY KEY,
  bal INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO wallets VALUES (1, 100), (2, 100);
