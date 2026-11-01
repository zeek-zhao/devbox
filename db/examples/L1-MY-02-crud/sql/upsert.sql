USE db_l1_my_02_crud;
INSERT INTO item (id, name, qty) VALUES (2, 'banana', 9) AS new
  ON DUPLICATE KEY UPDATE qty = new.qty;
