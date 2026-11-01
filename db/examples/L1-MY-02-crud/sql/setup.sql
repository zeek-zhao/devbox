USE db_l1_my_02_crud;
CREATE TABLE item (
  id   INT PRIMARY KEY,
  name VARCHAR(20) NOT NULL,
  qty  INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;
INSERT INTO item (id, name, qty) VALUES (1, 'apple', 3), (2, 'banana', 5);
