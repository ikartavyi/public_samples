/**
    This query performs the following steps:

    1. Retrieves data from both `custom_pricing` and `default_pricing`, 
       ensuring that any null values in the `ends_at` field are replaced with the current date.

    2. Uses the `LAG` window function to calculate values from the previous record for custom pricing, 
       such as the previous `fixed_rate`, `variable_rate`, and `ends_at` date, for each combination 
       of `customer_id` and `payment_method_id`.

    3. For custom pricing records where:
       - There is a gap of more than 1 day between the current record’s `starts_at` and the previous 
         record’s `ends_at`, or
       - No previous record exists in `custom_pricing` for the same `customer_id` and `payment_method_id`,
       the query checks whether any `default_pricing` record was active during this gap period.

    4. The final output selects the appropriate values for the previous (old) rates. If there is an overlap 
       with `default_pricing` during the identified gap, the old rates from the default pricing will be used. 
       Otherwise, the old rates from the previous custom pricing record will be used.

    5. The query ensures that only the most relevant `default_pricing` record is considered by using a 
       `ROW_NUMBER()` window function, partitioned by `customer_id`, `custom_pricing_id`, and `payment_method_id`,
       and ordered by the `ends_at` date in descending order.
*/

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

Data_join as (
    SELECT
        C.*,
        D.fixed_rate as default_fixed_rate,
        D.variable_rate as default_variable_rate,
        D.starts_at as default_starts_at,
        D.ends_at as default_ends_at,
        ROW_NUMBER() OVER (
            PARTITION BY 
                C.customer_id, C.custom_pricing_id, C.payment_method_id 
            ORDER BY 
                D.ends_at DESC
        ) AS row_n
    FROM
    (
        SELECT
            custom_pricing_id,
            customer_id,
            payment_method_id,
            starts_at as pricing_updated_at,
            fixed_rate as new_fixed_rate,
            variable_rate as new_variable_rate,
            LAG(fixed_rate) OVER (
                PARTITION BY customer_id, payment_method_id ORDER BY ends_at
            ) AS old_custom_fixed_rate,
            LAG(variable_rate) OVER (
                PARTITION BY customer_id, payment_method_id ORDER BY ends_at
            ) AS old_custom_variable_rate,
            LAG(ends_at) OVER (
                PARTITION BY customer_id, payment_method_id ORDER BY ends_at
            ) AS old_custom_price_ends_at
        FROM
            Custom_pricing as C
    ) AS C
    LEFT JOIN
        Default_pricing as D
        ON
        C.payment_method_id = D.payment_method_id
        AND C.pricing_updated_at > D.starts_at
        AND (
                (
                    C.old_custom_price_ends_at < D.ends_at

                    -- We're checking if the default pricing was effective only when the end date 
                    -- of the previous record doesn't immediately precede or equal with the start date 
                    -- of the new record, so that we can be certain there was a time gap that might 
                    -- be covered by the default pricing.
                    AND 
                        DATEDIFF(C.pricing_updated_at, C.old_custom_price_ends_at) > 1
                )
                OR C.old_custom_price_ends_at IS NULL   
        )
)

SELECT
    customer_id,
    payment_method_id,
    pricing_updated_at,
    new_fixed_rate,
    new_variable_rate,
    CASE
        WHEN 
            old_custom_price_ends_at < default_ends_at OR old_custom_price_ends_at IS NULL
        THEN default_fixed_rate
        ELSE old_custom_fixed_rate
    END as old_fixed_rate,
    CASE
        WHEN 
            old_custom_price_ends_at < default_ends_at OR old_custom_price_ends_at IS NULL
        THEN default_variable_rate
        ELSE old_custom_variable_rate
    END as old_variable_rate
FROM
    Data_join
WHERE
    row_n = 1