-- DEX Trading volume (New anf E2 users)
wallet_list AS ( -- List of wallets sender and reciever
        SELECT 
            block_time,
            event_name,
            from_wallet as wallet
        FROM essence
    UNION
        SELECT 
            block_time,
            event_name,
            to_wallet as wallet
        FROM essence
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
            ELSE 'New User'
        END AS tag
    FROM wallet_list
),
wallet_tag AS ( -- Ensure each wallet has a single tag by aggregating data
    SELECT 
        wallet, 
        MIN(tag) AS tag -- assign single 'E2 User' over 'New User' tag
    FROM tagged_wallets
    GROUP BY wallet
),
dex as ( -- DEX trading data
	SELECT 
    	project as dex,
    	block_date,
   		block_time,
    	block_number,
    	CASE
        	WHEN token_bought_symbol = 'ESS' THEN 'buy'
        	ELSE 'sell' END as trade_type,
    	token_bought_symbol as token_bought,
    	token_sold_symbol as token_sold,
    	round(token_bought_amount, 6) as token_bought_amount,
    	round(token_sold_amount, 6) as token_sold_amount,
    	round(amount_usd, 2) as amount_usd,
    	CASE
        	WHEN BYTEARRAY_LTRIM(tx_from) = FROM_HEX('0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad') THEN 'Uniswap Router'
        	WHEN BYTEARRAY_LTRIM(tx_from) = FROM_HEX('0x881d40237659c251811cec9c364ef91dc08d300c') THEN 'Metamask Router'
        	WHEN BYTEARRAY_LTRIM(tx_from) = FROM_HEX('0x6131b5fae19ea4f9d964eac0408e4408b66337b5') THEN 'KyberSwap Router'
        	WHEN BYTEARRAY_LTRIM(tx_from) = FROM_HEX('0xdef1c0ded9bec7f1a1670819833240f027b25eff') THEN '0x: Exchange Proxy'
        	WHEN BYTEARRAY_LTRIM(tx_from) = FROM_HEX('0x0ddc6f9ce13b985dfd730b8048014b342d1b54f7') THEN 'MEV Bot'
        	ELSE TRY_CAST(BYTEARRAY_LTRIM(tx_from) AS VARCHAR) END as wallet,
    	evt_index,
    	tx_hash
	FROM 
		dex.trades
	WHERE 
			blockchain = 'ethereum'
		and (token_bought_address= FROM_HEX('0x2c0687215Aca7F5e2792d956E170325e92A02aCA') 
		   	 or token_sold_address= FROM_HEX('0x2c0687215Aca7F5e2792d956E170325e92A02aCA')) -- Earth 2 contract
)
SELECT 
    x.block_date as date_time,
    wt.tag,
    sum(x.amount_usd) as trade_volume_usd
FROM 
	dex x
LEFT JOIN wallet_tag wt ON x.wallet=wt.wallet
where
	wt.tag IS NOT NULL -- null Tags are for aggregator wallets
GROUP BY 
	1, 2
ORDER BY 1 desc
