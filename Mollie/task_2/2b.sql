WITH

Custom_pricing AS (
    SELECT
        customer_id,
        custom_pricing_id,
        payment_method_id,
        starts_at,
        IFNULL(ends_at, CURRENT_DATE()) AS ends_at,
        fixed_rate,
        variable_rate
    FROM
        test_database.custom_pricing
),

Default_pricing AS (
    SELECT
        payment_method_id,
        starts_at,
        IFNULL(ends_at, CURRENT_DATE()) AS ends_at,
        fixed_rate,
        variable_rate
    FROM
        test_database.default_pricing
),

Joined_payments_data AS (
    SELECT
        P.payment_id,
        P.customer_id,
        P.payment_date,
        P.payment_method_id,
        P.total_volume,
        IFNULL(
            CP.fixed_rate,
            DP.fixed_rate
        ) as fixed_rate,
        IFNULL(
            CP.variable_rate,
            DP.variable_rate
        ) as variable_rate
    FROM
        test_database.payments as P
    LEFT JOIN
        Custom_pricing as CP
        ON 
        P.customer_id = CP.customer_id
        AND P.payment_method_id = CP.payment_method_id
        AND P.payment_date BETWEEN CP.starts_at AND CP.ends_at
    LEFT JOIN
        Default_pricing as DP
        ON
        P.payment_method_id = DP.payment_method_id
        AND P.payment_date BETWEEN DP.starts_at AND DP.ends_at
)

SELECT
    payment_id,
    -- I assume that a single payment can't have multiple transactions using 
    -- different payment methods. 
    -- Therefore, I'm not grouping and aggregating the data.
    total_volume,
    IFNULL(fixed_rate, 0) as fixed_rate,
    IFNULL(variable_rate, 0) as variable_rate,
    IFNULL(fixed_rate, 0) as total_fixed_fee,
    total_volume * IFNULL(variable_rate, 0) as total_variable_fee,
    (
        IFNULL(fixed_rate, 0) + 
        total_volume * IFNULL(variable_rate, 0)
    ) as total_fee
FROM
    Joined_payments_data