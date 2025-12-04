USE studentdb;
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);
INSERT INTO test_table (name) VALUES ('Bahija');
SELECT * FROM test_table;
