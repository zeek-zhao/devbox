USE db_e_E_013_backup_corrupt_detect;
CREATE TABLE orders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  region VARCHAR(10) NOT NULL,
  amount INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO orders (region, amount) VALUES
  ('north', 120),
  ('south', 340),
  ('west', 90);
