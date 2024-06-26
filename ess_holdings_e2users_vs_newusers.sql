-- Essence Wallet Holdings Over time E2 Users vs New users
wallet_list AS ( -- List of wallets sender and reciever
        SELECT 
            block_time,
            event_name,
            from_wallet as wallet
        FROM 
        	essence
    UNION
        SELECT 
            block_time,
            event_name,
            to_wallet as wallet
        FROM 
        	essence
),
tagged_wallets AS ( -- Tagged Wallets List by category based on the first transaction
    SELECT
        wallet,
        CASE
            WHEN wallet = 'Earth2' THEN 'Earth2'
            WHEN wallet = '0x' THEN 'Burn Wallet'
            WHEN wallet = 'Earth2 Connected_2' or wallet = 'Earth2 Connected' THEN 'Earth2 Connected'
            WHEN wallet IN ('0x4f0a43c5bf658e2661e52b85588071dc3c66b2f3', -- wallets that recieved ESS transfer from E2 Users
                            '0xf9b2b01d61ec08f8ad4660a1e47adee4b7cd7693',
                            '0xb192ab4ba931f570a7cbd9036dbf1bcb4cfdf8ff',
                            '0x989b2e9c9f5cdd67b198d94568493b0aadae238a',
                            '0x5874d937c8da8c154448ba960e3f20aa64d1a8f8',
                            '0xfb28c03a6e7da302b57f7205610ff03b80cdf38e',
                            '0x542e347008d83659218dc3e73b633681cf7fd708',
                            '0x6a515d6d6ddd558f18c0e29cec19a059399896c0',
                            '0x1a72b8da819a303f1d30398d86b2fa226c3b5a0c',
                            '0x95657776c06f6e849404ca88b9098c6a156368c6',
                            '0x5a81178cbfa43a243ffae7b9c8abc2e2c0dec671',
                            '0xa8eb0f43ba39a33966174df6a1601a0ebaa92d77',
                            '0xb35182a8fe47534ece75d6673518fcd3ca557e6a',
                            '0xa1e4238551b3fa92a0cdb402eadc8490f62fbb2b',
                            '0x17b1df1224b9d8f67459cb76504536b5ca2eb6b1',
                            '0xe3bac31a91a7b185541872d4ea2d868f857adedd',
                            '0x5d5f9fdb0bdecb707793070163fb0dce67eb0baa',
                            '0x69c4261718c7108a29b702d0bb62ba195e7e2b58') THEN 'E2 User'
            WHEN event_name = 'Earth2 Withdraw' or event_name = 'Earth2 Deposit' THEN 'E2 User'
            WHEN wallet IN ('Uniswap: Universal Router', 'Uniswap: Router2', 'Uniswap: Order Reactor', 'Uniswap: ESS/WETH pool', 'BitKeep: BKSwap',
                            'MEV Bot', 'Uniswap V3: Positions NFT', 'Fee Collector Uniswap', 'Uniswap V3: ESS 6', 'Uniswap: Permit2', 'KyberSwap: Router',
                            'KyberSwap: Double Sign Limit Order', '1inch: Router V6', '0x: Exchange Proxy', 'inch v5: Aggregation Router', 'Looter: Router') THEN 'Aggregators'
            ELSE 'New User' END AS tag
    FROM 
    	wallet_list
),
wallet_tag AS ( -- Ensure each wallet has a single tag by aggregating data
    SELECT 
        wallet, 
        MIN(tag) AS tag -- assign single 'E2 User' over 'New User' tag
    FROM 
    	tagged_wallets
    GROUP BY 
    	wallet
),
transactions AS ( -- Combine incoming and outgoing transactions, normalizing ESS quantities
    SELECT
        e.block_time,
        e.index,
        e.to_wallet AS wallet,
        e.ess_quantity AS ess
    FROM 
    	essence e
 UNION ALL
    SELECT
        e.block_time,
        e.index,
        e.from_wallet AS wallet,
        -e.ess_quantity AS ess
    FROM 
    	essence e
),
tagged_transactions AS ( -- Ensure each transaction retains the initial tag
    SELECT
        t.block_time,
        t.index,
        t.wallet,
        t.ess,
        wt.tag
    FROM 
    	transactions t
    LEFT JOIN wallet_tag wt ON t.wallet = wt.wallet
),
users as (
    SELECT
        date(block_time) as date_time,
        count( DISTINCT CASE
                            WHEN tag = 'E2 User' THEN wallet
                            ELSE null END) as e2_users,
        count( DISTINCT CASE
                            WHEN tag = 'New User' THEN wallet
                            ELSE null END) as new_wallets
    FROM 
    	tagged_transactions
    GROUP BY 1
)
SELECT
    DISTINCT date(tt.block_time) as date_time,
    sum(CASE
            WHEN tt.tag = 'E2 User' THEN ess
            ELSE 0 END) OVER(PARTITION BY date(tt.block_time)) as e2_user_ess,
    sum(CASE
            WHEN tt.tag = 'E2 User' THEN ess
            ELSE 0 END) OVER (ORDER BY date(tt.block_time)) as e2_user_ess_cumulative,        
    sum(CASE
            WHEN tt.tag = 'New User' THEN ess
            ELSE 0 END) OVER(PARTITION BY date(tt.block_time)) as new_user_ess,
    sum(CASE
            WHEN tt.tag = 'New User' THEN ess
            ELSE 0 END) OVER (ORDER BY date(tt.block_time)) as new_user_ess_cumulative,
    sum(CASE
            WHEN tt.tag = 'Earth2' THEN ess
            ELSE 0 END) OVER(PARTITION BY date(tt.block_time)) as earth2_ess,
    sum(CASE
            WHEN tt.tag = 'Earth2' THEN ess
            ELSE 0 END) OVER (ORDER BY date(tt.block_time)) as earth2_ess_cumulative,
    u.e2_users,
    u.new_wallets
FROM 
	tagged_transactions tt
LEFT JOIN users u ON date(tt.block_time)=u.date_time
WHERE
    date(tt.block_time) > date('2024-05-28')
ORDER BY 1