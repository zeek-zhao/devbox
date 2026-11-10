USE db_e_E_007_query_timeout;
CREATE TABLE heat (
  id INT PRIMARY KEY AUTO_INCREMENT,
  x INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO heat (x) VALUES (1);
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
INSERT INTO heat (x) SELECT x FROM heat;
CREATE TABLE accounts (
  id INT PRIMARY KEY,
  bal INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO accounts VALUES (1, 100), (2, 100);
