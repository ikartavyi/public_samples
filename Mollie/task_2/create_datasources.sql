DROP TABLE IF EXISTS test_database.organizations;
DROP TABLE IF EXISTS test_database.payments;
DROP TABLE IF EXISTS test_database.custom_pricing;
DROP TABLE IF EXISTS test_database.default_pricing;

-- Create Organizations table
CREATE TABLE test_database.organizations (
    customer_id INT,
    country_code VARCHAR(2),
    organization_name VARCHAR(255),
    sales_manager_id INT,
    first_payment_date DATE
);

INSERT INTO test_database.organizations (customer_id, country_code, organization_name, sales_manager_id, first_payment_date)
VALUES
    (345, 'GB', 'Electronics Ltd', 358787, '2018-01-01'),
    (346, 'NL', 'Furniture Store BV', NULL, '2018-02-12'),
    (347, 'BE', 'Food delivery Inc', 235567, '2019-03-18'),
    (348, 'NL', 'Jewelry store', NULL, '2019-04-25');

-- Create Payments table
CREATE TABLE test_database.payments (
    payment_id INT,
    customer_id INT,
    payment_date DATE,
    payment_method_id INT,
    total_volume DECIMAL(10, 2)
);

INSERT INTO test_database.payments (payment_id, customer_id, payment_date, payment_method_id, total_volume)
VALUES
    (1145, 345, '2020-02-01', 3, 64.55),
    (1146, 345, '2020-02-02', 11, 24.35),
    (1147, 346, '2020-02-03', 15, 6400.00),
    (1148, 346, '2020-02-01', 3, 500.00);

-- Create Custom_Pricing table
CREATE TABLE test_database.custom_pricing (
    customer_id INT,
    custom_pricing_id INT,
    payment_method_id INT,
    starts_at DATE,
    ends_at DATE,
    fixed_rate DECIMAL(5, 3),
    variable_rate DECIMAL(5, 3)
);

INSERT INTO test_database.custom_pricing (customer_id, custom_pricing_id, payment_method_id, starts_at, ends_at, fixed_rate, variable_rate)
VALUES
    (1001, 566, 11, '2018-10-01', '2018-12-05', 0.15, 0.030),
    (1000, 567, 3, '2018-01-01', '2018-07-11', 0.06, 0.00),
    (1000, 568, 3, '2018-07-11', NULL, 0.057, 0.00),
    (1000, 569, 11, '2019-01-01', NULL, 0.21, 0.028),
    (1001, 570, 11, '2019-01-01', NULL, 0.22, 0.016);

-- Create Default_pricing table
CREATE TABLE test_database.default_pricing (
    payment_method_id INT,
    starts_at DATE,
    ends_at DATE,
    fixed_rate DECIMAL(5, 3),
    variable_rate DECIMAL(5, 3)
);

INSERT INTO test_database.default_pricing (payment_method_id, starts_at, ends_at, fixed_rate, variable_rate)
VALUES
    (3, '2018-01-01', '2018-12-31', 0.05, 0.00),
    (3, '2019-01-01', NULL, 0.25, 0.00),
    (11, '2017-01-01', '2018-12-07', 0.09, 0.007),
    (11, '2018-12-08', '2018-12-31', 0.01, 0.002),
    (11, '2019-01-01', NULL, 0.20, 0.015),
    (15, '2020-01-01', NULL, 0.18, 0.02),
    (7, '2021-05-01', NULL, 0.10, 0.005),
    (4, '2019-06-15', '2020-06-15', 0.09, 0.01),
    (9, '2022-03-01', NULL, 0.17, 0.025),
    (6, '2018-11-01', '2020-12-31', 0.08, 0.02),
    (12, '2023-01-01', NULL, 0.21, 0.018),
    (5, '2020-09-01', '2021-09-01', 0.12, 0.00),
    (10, '2020-10-15', NULL, 0.13, 0.03),
    (13, '2017-01-01', '2018-01-01', 0.07, 0.01);
