CREATE TABLE IF NOT EXISTS customer (
  customer_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL,
  mobile_number VARCHAR(20) NOT NULL,
  created_at DATE NOT NULL,
  updated_at DATE DEFAULT NULL,
  updated_by VARCHAR(20) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS accounts (
  account_number SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customer(customer_id),
  account_type VARCHAR(100) NOT NULL,
  branch_address VARCHAR(200) NOT NULL,
  communication_sw BOOLEAN,
  created_at DATE NOT NULL,
  created_by VARCHAR(20) NOT NULL,
  updated_at DATE DEFAULT NULL,
  updated_by VARCHAR(20) DEFAULT NULL
);