USE db_e_E_012_upsert_race;
CREATE TABLE sku_stock (
  sku VARCHAR(20) PRIMARY KEY,
  qty INT NOT NULL
) ENGINE=InnoDB;
INSERT INTO sku_stock VALUES ('widget-a', 100);
