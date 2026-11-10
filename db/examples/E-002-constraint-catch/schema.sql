USE db_e_E_002_constraint_catch;
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(64) NOT NULL UNIQUE,
  age INT NOT NULL,
  CONSTRAINT chk_age CHECK (age >= 0)
) ENGINE=InnoDB;
CREATE TABLE orders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;
INSERT INTO users (email, age) VALUES ('a@devbox.local', 30);
