-- COUNTERS WITH MAIN METRICS
total_ess_holders as ( -- Total ESS anf ESS Holders
     with a as (select 
                    to_wallet,
                    sum(ess_quantity) as income_ess
                from essence
                group by 1
                ),
           b as (select 
                    from_wallet,
                    sum(ess_quantity) as outcome_ess
                from essence
                group by 1
                ),
     result as (SELECT
                    round(sum(a.income_ess - coalesce(b.outcome_ess, 0)), 1) as total_ess,
                    count(distinct a.to_wallet) as total_holders
                FROM a
                LEFT JOIN b on a.to_wallet=b.from_wallet
                WHERE ROUND(a.income_ess - coalesce(b.outcome_ess, 0), 2) > 0
                )
    SELECT
        row_number() over(order by total_ess) as row,
        total_ess,
        total_holders
    FROM result
),
platform_ess_burn as ( -- Total Burned ESS
      with cte as ( SELECT
                        ROUND(sum(CASE 
                                    WHEN to_wallet = 'Earth2' THEN ess_quantity
                                    WHEN from_wallet = 'Earth2' THEN (-1) * ess_quantity
                                    ELSE 0 END), 2) AS e2_platform,
                        ROUND(sum(CASE
                                    WHEN event_name = 'Burn' THEN ess_quantity
                                    ELSE NULL END), 2) AS ess_burned
                    FROM essence
                    WHERE to_wallet IN ('Earth2', '0x')  or from_wallet IN ('Earth2', '0x')
                    )
        SELECT
            row_number() over(order by e2_platform) as row,
            e2_platform,
            ess_burned
        FROM cte
)
SELECT --  final table for visualization
    t.total_ess,
    p.e2_platform,
    t.total_holders,
    p.ess_burned
FROM total_ess_holders t
LEFT JOIN platform_ess_burn p ON t.row=p.row;