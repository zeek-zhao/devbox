USE db_e_E_008_permission_denied;
CREATE TABLE secrets (
  id INT PRIMARY KEY AUTO_INCREMENT,
  note VARCHAR(30) NOT NULL
) ENGINE=InnoDB;
INSERT INTO secrets (note) VALUES ('seed');
