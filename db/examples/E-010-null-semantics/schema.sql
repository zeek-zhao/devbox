USE db_e_E_010_null_semantics;
CREATE TABLE orders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  region VARCHAR(10) NULL,
  amount INT NULL
) ENGINE=InnoDB;
INSERT INTO orders (region, amount) VALUES
  ('north', 100),
  ('north', NULL),
  (NULL, 200),
  ('south', NULL),
  (NULL, NULL);
