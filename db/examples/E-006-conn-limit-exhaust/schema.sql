USE db_e_E_006_conn_limit_exhaust;
CREATE TABLE lease_log (
  id INT PRIMARY KEY AUTO_INCREMENT,
  note VARCHAR(30) NOT NULL
) ENGINE=InnoDB;
INSERT INTO lease_log (note) VALUES ('quota=2');
