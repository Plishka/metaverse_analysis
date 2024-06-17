-- ESS WALLET CHECKER - WALLET BALANCE OVER TIME
transactions AS ( -- Combine incoming and outgoing transactions, normalizing ESS quantities
 			   SELECT
      				e.block_date,
      				e.to_wallet AS wallet,
      				e.ess_quantity AS ess
    			FROM
      				essence e
      				
			UNION all
			
    			SELECT
      				e.block_date,
      				e.from_wallet AS wallet,
      				- e.ess_quantity AS ess
    			FROM
      				essence e
 ),
dates as ( -- CREATE CALENDAR DAYS SECUENCE
    	WITH date_bounds AS (
        	SELECT
            	MIN(block_date) AS min_date,
            	MAX(block_date) AS max_date
        	FROM 
        		essence
    				)
            	SELECT
                    sequence_element AS calendar_days
            	FROM 
            		date_bounds
            	CROSS JOIN UNNEST(SEQUENCE(min_date, max_date, INTERVAL '1' DAY)) AS t(sequence_element)
),
agg as ( -- WALLET BALANCE
        SELECT
                date(t.block_date) as date_time,
                sum(t.ess) as ess
        FROM 
        	transactions t
        WHERE 
             t.wallet = '{{insert wallet to check balance change over time:}}' -- CHECKER
        GROUP BY 1
)
SELECT
    d.calendar_days as date_time,
    sum(COALESCE(a.ess, 0)) over(order by date(d.calendar_days)) as ess_balance
FROM 
  dates d 
LEFT JOIN agg a on a.date_time=d.calendar_days
ORDER BY
  1