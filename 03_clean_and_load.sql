-- 03_clean_and_load.sql
-- Clean and load data from staging tables to market_data

-- 1. Load Binance data
INSERT OR IGNORE INTO market_data (exchange_id, asset_id, open_price, high_price, low_price, close_price, volume_btc, trade_date)
SELECT 
    1,                                      -- exchange_id for Binance
    1,                                      -- asset_id for BTC
    CAST(open AS REAL),
    CAST(high AS REAL),
    CAST(low AS REAL),
    CAST(close AS REAL),
    CAST(volume_btc AS REAL),
    DATE(date_raw)
FROM staging_binance
WHERE close IS NOT NULL AND close != '' AND close != 'close';

-- 2. Load Bitfinex data
INSERT OR IGNORE INTO market_data (exchange_id, asset_id, open_price, high_price, low_price, close_price, volume_btc, trade_date)
SELECT 
    3,                                      -- exchange_id for Bitfinex
    1,
    CAST(open AS REAL),
    CAST(high AS REAL),
    CAST(low AS REAL),
    CAST(close AS REAL),
    CAST(volume_btc AS REAL),
    DATE(date_raw)
FROM staging_bitfinex
WHERE close IS NOT NULL AND close != '';

-- 3. Load Bitstamp data
INSERT OR IGNORE INTO market_data (exchange_id, asset_id, open_price, high_price, low_price, close_price, volume_btc, trade_date)
SELECT 
    4,                                      -- exchange_id for Bitstamp
    1,
    CAST(open AS REAL),
    CAST(high AS REAL),
    CAST(low AS REAL),
    CAST(close AS REAL),
    CAST(volume_btc AS REAL),
    DATE(date_raw)
FROM staging_bitstamp
WHERE close IS NOT NULL AND close != '';

-- 4. Load Coinbase data
INSERT OR IGNORE INTO market_data (exchange_id, asset_id, open_price, high_price, low_price, close_price, volume_btc, trade_date)
SELECT 
    2,                                      -- exchange_id for Coinbase
    1,
    CAST(open AS REAL),
    CAST(high AS REAL),
    CAST(low AS REAL),
    CAST(close AS REAL),
    CAST(volume AS REAL),
    DATE(date_raw)
FROM staging_coinbase
WHERE close IS NOT NULL AND close != '' AND close != 'close';

-- Verification: Check row count per exchange
SELECT 
    e.exchange_name,
    COUNT(*) AS row_count,
    MIN(m.trade_date) AS first_date,
    MAX(m.trade_date) AS last_date,
    MIN(m.close_price) AS min_price,
    MAX(m.close_price) AS max_price
FROM market_data m
JOIN exchanges e ON m.exchange_id = e.exchange_id
GROUP BY e.exchange_name
ORDER BY e.exchange_id;