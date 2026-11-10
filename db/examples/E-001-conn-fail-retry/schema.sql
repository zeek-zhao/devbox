USE db_e_E_001_conn_fail_retry;
CREATE TABLE conn_log (
  id INT PRIMARY KEY AUTO_INCREMENT,
  err_code INT NULL
) ENGINE=InnoDB;
