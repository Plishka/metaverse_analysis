CREATE VIEW essence as -- DECODE RAW BLOCKCHAIN data and FILTERING only NEEDED. This table is used as view for all qeries
  SELECT
    block_date,
    block_time,
    block_number,
    CASE
        WHEN contract_address = FROM_HEX('0x2c0687215Aca7F5e2792d956E170325e92A02aCA') THEN 'Essence'-- Essence Token Contract
        ELSE TRY_CAST(contract_address AS VARCHAR) END AS contract_name,
    CASE -- label events by known addresses
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x') THEN 'Mint'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x') THEN 'Burn'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x68d332EC97800Aa1a112160195cc281978eC8Eea') 
         and BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x528a7d60dAf08A98e39220B1De6557be6afe9Bbb') THEN 'E2 Batch'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x68d332EC97800Aa1a112160195cc281978eC8Eea') THEN 'Earth2 Withdraw'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x68d332EC97800Aa1a112160195cc281978eC8Eea') THEN 'Earth2 Deposit'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xC36442b4a4522E871399CD717aBDD847Ab11FE88') 
         and BYTEARRAY_LTRIM(topic1) <> FROM_HEX('0x2afeaf811fe57b72cb496e841113b020a5cf0d60') THEN 'Add Liquidity Uniswap'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0xC36442b4a4522E871399CD717aBDD847Ab11FE88') THEN 'Remove Liquidity Uniswap'
        ELSE null END as event_name,
    CASE -- label known sender wallets 
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x68d332EC97800Aa1a112160195cc281978eC8Eea') THEN 'Earth2'-- Earth2 Platform Wallet
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x40399de3a3ca6a9df0d04c62d20dd08b8eafe280') THEN 'Earth2 Connected' 	-- May be Earth2 Treasury
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x5086d1e7314d9c24a9c4386dcedeec5549502989') THEN 'Earth2 Connected_2' -- May be Earth2 Treasury
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x528a7d60dAf08A98e39220B1De6557be6afe9Bbb') THEN 'Earth2 Batch' -- Earth2 Batching contract used to withdraw tokens from platform in batches
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad') THEN 'Uniswap: Universal Router'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45') 
          OR BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x7a250d5630b4cf539739df2c5dacb4c659f2488d') THEN 'Uniswap: Router2'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x6000da47483062a0d734ba3dc7576ce6a0b645c4') THEN 'Uniswap: Order Reactor'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x2afeaf811fe57b72cb496e841113b020a5cf0d60')                                 -- First Bigger Pool
          OR BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x26040bcab8c8e352e2ec3f66e4c4b8ca4658b2')   THEN 'Uniswap: ESS/WETH pool'   -- Second Smaller Pool
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x2f2dd99235cb728fc79af575f1325eaa270f0c99') THEN 'BitKeep: BKSwap'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x6b75d8af000000e20b7a7ddf000ba900b4009a80') 
          OR BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x24902aa0cf0000a08c0ea0b003b0c0bf600000e0')
          OR BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x74de5d4fcbf63e00296fd95d33236b9794016631') THEN 'MEV Bot'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0xC36442b4a4522E871399CD717aBDD847Ab11FE88') THEN 'Uniswap V3: Positions NFT'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0xfee13a103a10d593b9ae06b3e05f2e7e1c')       THEN 'Fee Collector Uniswap'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x22d473030f116ddee9f6b43ac78ba3')           THEN 'Uniswap: Permit2'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x6131b5fae19ea4f9d964eac0408e4408b66337b5') THEN 'KyberSwap: Router'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0xcab2fa2eeab7065b45cbcf6e3936dde2506b4f6c') THEN 'KyberSwap: Double Sign Limit Order'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x111111125421ca6dc452d289314280a0f8842a65') THEN '1inch: Router V6'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0xdef1c0ded9bec7f1a1670819833240f027b25eff') THEN '0x: Exchange Proxy'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0x1111111254eeb25477b68fb85ed929f73a960582') THEN 'inch v5: Aggregation Router'
        WHEN BYTEARRAY_LTRIM(topic1) = FROM_HEX('0xf268035f5f7fa5bd43eb8b84723d880ec2748d81') THEN 'Looter: Router'
        ELSE TRY_CAST(BYTEARRAY_LTRIM(topic1) AS VARCHAR) END AS from_wallet,
    CASE
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x68d332EC97800Aa1a112160195cc281978eC8Eea') THEN 'Earth2'-- Earth2 Platform Wallet
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x40399de3a3ca6a9df0d04c62d20dd08b8eafe280') THEN 'Earth2 Connected' 	-- May be Earth2 Treasury
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x5086d1e7314d9c24a9c4386dcedeec5549502989') THEN 'Earth2 Connected_2' -- May be Earth2 Treasury
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x528a7d60dAf08A98e39220B1De6557be6afe9Bbb') THEN 'Earth2 Batch' -- Earth2 Batching contract used to withdraw tokens from platform in batches
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad') THEN 'Uniswap: Universal Router'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45') 
          OR BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x7a250d5630b4cf539739df2c5dacb4c659f2488d') THEN 'Uniswap: Router2'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x6000da47483062a0d734ba3dc7576ce6a0b645c4') THEN 'Uniswap: Order Reactor'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x2afeaf811fe57b72cb496e841113b020a5cf0d60')                                 -- First Bigger Pool
          OR BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x26040bcab8c8e352e2ec3f66e4c4b8ca4658b2')   THEN 'Uniswap: ESS/WETH pool'   -- Second Smaller Pool
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x2f2dd99235cb728fc79af575f1325eaa270f0c99') THEN 'BitKeep: BKSwap'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x6b75d8af000000e20b7a7ddf000ba900b4009a80') 
          OR BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x24902aa0cf0000a08c0ea0b003b0c0bf600000e0')
          OR BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xd40b595b94918a28b27d1e2c66f43a51d3')
          OR BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x74de5d4fcbf63e00296fd95d33236b9794016631') THEN 'MEV Bot'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xC36442b4a4522E871399CD717aBDD847Ab11FE88') THEN 'Uniswap V3: Positions NFT'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xfee13a103a10d593b9ae06b3e05f2e7e1c')       THEN 'Fee Collector Uniswap'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x22d473030f116ddee9f6b43ac78ba3')           THEN 'Uniswap: Permit2'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x6131b5fae19ea4f9d964eac0408e4408b66337b5') THEN 'KyberSwap: Router'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xcab2fa2eeab7065b45cbcf6e3936dde2506b4f6c') THEN 'KyberSwap: Double Sign Limit Order'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x111111125421ca6dc452d289314280a0f8842a65') THEN '1inch: Router V6'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xdef1c0ded9bec7f1a1670819833240f027b25eff') THEN '0x: Exchange Proxy'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0x1111111254eeb25477b68fb85ed929f73a960582') THEN 'inch v5: Aggregation Router'
        WHEN BYTEARRAY_LTRIM(topic2) = FROM_HEX('0xf268035f5f7fa5bd43eb8b84723d880ec2748d81') THEN 'Looter: Router'
        ELSE TRY_CAST(BYTEARRAY_LTRIM(topic2) AS VARCHAR) END AS to_wallet,
    ROUND(BYTEARRAY_TO_UINT256(data) / 1000000000000000000.0, 10) AS ess_quantity, -- transform data to Token view (18 decimal token)
    index,
    tx_hash,
    block_hash
  FROM 
  	ethereum.logs
  WHERE
            contract_address = FROM_HEX('0x2c0687215Aca7F5e2792d956E170325e92A02aCA') -- Earth2 Essence (ESS) contract address
        AND BYTEARRAY_TO_UINT256(data) / 1000000000000000000 < 1000000000 -- handle errors in essence calculation setting an arbitrary large value that is still within a reasonable range
        AND BYTEARRAY_LTRIM(topic2) <> FROM_HEX('0x528a7d60dAf08A98e39220B1De6557be6afe9Bbb') -- batching smart contract used to withdraw tokens in batches from main wallet
        AND topic0 <> FROM_HEX('0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925') -- filter data from token approvals for swaps, liquidity add and other
        AND topic1<>topic2 -- filter data from self-transfers
  ORDER BY 2 DESC