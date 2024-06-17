-- Earth 2 Balance over time vs Withdrawals and Deposits Chart
calculations as (
    select
        distinct block_date as date_time,
        round(SUM(case 
                when event_name IN ('Earth2 Deposit', 'Mint') then ess_quantity
                else 0 end) OVER (partition by block_date), 0) as platform_deposits,
        round(SUM(case 
                when event_name IN ('Earth2 Withdraw', 'Burn') then ess_quantity
                else 0 end) OVER (partition by block_date), 0) as platform_withdraws,
        round (SUM(case 
                when event_name IN ('Earth2 Deposit', 'Mint') then ess_quantity
                when event_name IN ('Earth2 Withdraw', 'Burn') then -ess_quantity
                else 0 end) OVER (order by block_date), 0) as platform_balance
    from essence
    where 
        event_name IN ('Earth2 Deposit', 'Earth2 Withdraw', 'Mint', 'Burn')
    order by 1 
)
select
	*
from 
	calculations
where
    date_time > date('2024-05-28')
