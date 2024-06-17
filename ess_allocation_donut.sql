-- ESS Allocation Donut Chart
totals as (
	SELECT
    	row_number() over (order by 1) as num,
    	round(sum(case -- Earth 2 total ESS
        	    when to_wallet = 'Earth2'   then ess_quantity
            	when from_wallet = 'Earth2' then -ess_quantity
            	else 0 end), 0) AS e2_ess_total,
    	round(sum(case -- Earth 2 Connected (Treasury) total ESS
        	    when to_wallet = 'Earth2 Connected'  then ess_quantity
            	when from_wallet = 'Earth2 Connected'  then -ess_quantity
            	else 0 end)
    			+
    		  sum(CASE
            	when to_wallet = 'Earth2 Connected_2'  then ess_quantity
            	when from_wallet = 'Earth2 Connected_2'  then -ess_quantity
            	else 0 end), 0) AS connected_ess_total,  
    	round(sum(case -- ESS Liquidity Pools
            	when to_wallet = 'Uniswap: ESS/WETH pool'   then ess_quantity
            	when from_wallet = 'Uniswap: ESS/WETH pool' then -ess_quantity
            	else 0 end), 0) AS liquidity_ess_total
	FROM essence
	ORDER BY 3 desc, 1 desc
),
totals2 as ( -- TOTAL ESS count
    with a as ( 
        select 
            to_wallet,
            sum(ess_quantity) as income_ess
        from essence
        group by 1
            ),
    b as ( 
        select 
            from_wallet,
            sum(ess_quantity) as outcome_ess
        from essence
        group by 1
            )
				SELECT
    				row_number() over (order by 1) as num,
    				round(sum(a.income_ess - coalesce(b.outcome_ess, 0)), 1) as total_ess
				FROM a
				LEFT JOIN b on a.to_wallet=b.from_wallet
				WHERE 
					round(a.income_ess - coalesce(b.outcome_ess, 0), 2) > 0
)
SELECT -- final table for Donyt Chart
    'Earth 2' as "Wallet Type",
    e2_ess_total as "ESS"
FROM totals 
    UNION ALL
SELECT
    'E2 Conect' as wallet_type,
    connected_ess_total as connected_ess_total
FROM totals
    UNION ALL
SELECT
    'Liquidity' as wallet_type,
    liquidity_ess_total as liquidity_ess_total
FROM totals
    UNION ALL
SELECT
    'User Wallets' as wallet_type,
    t2.total_ess - t1.e2_ess_total - t1.connected_ess_total - t1.liquidity_ess_total as user_wallets_ess_total
FROM totals t1
JOIN totals2 t2 on t1.num=t2.num
