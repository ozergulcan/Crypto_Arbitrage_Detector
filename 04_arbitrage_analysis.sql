-- 04_arbitrage_analysis.sql
-- Arbitrage analysis queries for SQLite

-- 1. Daily price spread (highest vs lowest across exchanges)
SELECT 
    trade_date,
    COUNT(DISTINCT exchange_id) AS exchange_count,
    MIN(close_price) AS min_price,
    MAX(close_price) AS max_price,
    ROUND(MAX(close_price) - MIN(close_price), 2) AS spread_usd,
    ROUND((MAX(close_price) - MIN(close_price)) / MIN(close_price) * 100, 4) AS spread_pct
FROM market_data
GROUP BY trade_date
HAVING COUNT(DISTINCT exchange_id) > 1
ORDER BY spread_pct DESC
LIMIT 20;

-- 2. Create view for arbitrage opportunities (gross profit)
DROP VIEW IF EXISTS arbitrage_view;
CREATE VIEW arbitrage_view AS
SELECT 
    m1.trade_date,
    e1.exchange_name AS buy_exchange,
    e2.exchange_name AS sell_exchange,
    m1.close_price AS buy_price,
    m2.close_price AS sell_price,
    ROUND(m2.close_price - m1.close_price, 2) AS gross_profit_usd,
    ROUND((m2.close_price - m1.close_price) / m1.close_price * 100, 4) AS gross_profit_pct
FROM market_data m1
JOIN market_data m2 ON m1.trade_date = m2.trade_date
JOIN exchanges e1 ON m1.exchange_id = e1.exchange_id
JOIN exchanges e2 ON m2.exchange_id = e2.exchange_id
WHERE m1.exchange_id != m2.exchange_id
  AND m2.close_price > m1.close_price;

-- 3. Net profit after fees using a CTE
WITH arbitrage_with_fees AS (
    SELECT 
        av.trade_date,
        av.buy_exchange,
        av.sell_exchange,
        av.buy_price,
        av.sell_price,
        av.gross_profit_pct,
        tf1.taker_fee AS buy_fee,
        tf2.taker_fee AS sell_fee
    FROM arbitrage_view av
    JOIN exchanges e1 ON av.buy_exchange = e1.exchange_name
    JOIN exchanges e2 ON av.sell_exchange = e2.exchange_name
    JOIN trading_fees tf1 ON e1.exchange_id = tf1.exchange_id
    JOIN trading_fees tf2 ON e2.exchange_id = tf2.exchange_id
)
SELECT 
    trade_date,
    buy_exchange,
    sell_exchange,
    buy_price,
    sell_price,
    gross_profit_pct,
    ROUND(gross_profit_pct - (buy_fee + sell_fee) * 100, 4) AS net_profit_pct,
    CASE 
        WHEN gross_profit_pct > (buy_fee + sell_fee) * 100 THEN '✅ Profitable'
        ELSE '❌ Loss'
    END AS status
FROM arbitrage_with_fees
ORDER BY net_profit_pct DESC
LIMIT 30;

-- 4. Summary of best exchange pairs
SELECT 
    e1.exchange_name AS buy_exchange,
    e2.exchange_name AS sell_exchange,
    COUNT(*) AS opportunity_count,
    ROUND(AVG((m2.close_price - m1.close_price) / m1.close_price * 100), 4) AS avg_gross_pct,
    ROUND(AVG((m2.close_price - m1.close_price) / m1.close_price * 100 - (tf1.taker_fee + tf2.taker_fee) * 100), 4) AS avg_net_pct
FROM market_data m1
JOIN market_data m2 ON m1.trade_date = m2.trade_date AND m1.exchange_id < m2.exchange_id
JOIN exchanges e1 ON m1.exchange_id = e1.exchange_id
JOIN exchanges e2 ON m2.exchange_id = e2.exchange_id
JOIN trading_fees tf1 ON m1.exchange_id = tf1.exchange_id
JOIN trading_fees tf2 ON m2.exchange_id = tf2.exchange_id
WHERE m2.close_price > m1.close_price
GROUP BY e1.exchange_name, e2.exchange_name
ORDER BY avg_net_pct DESC;