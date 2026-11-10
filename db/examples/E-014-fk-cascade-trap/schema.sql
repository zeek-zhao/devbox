USE db_e_E_014_fk_cascade_trap;
CREATE TABLE customers (
  id INT PRIMARY KEY,
  name VARCHAR(20) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE orders (
  id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  note VARCHAR(30) NULL,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
    REFERENCES customers (id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE invoices (
  id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id)
    REFERENCES customers (id) ON DELETE CASCADE
) ENGINE=InnoDB;
INSERT INTO customers VALUES (1, 'alice'), (2, 'bob');
INSERT INTO orders VALUES (101, 1, NULL), (102, 1, NULL);
INSERT INTO invoices VALUES (201, 2), (202, 2);
