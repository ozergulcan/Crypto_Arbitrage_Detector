-- 05_save_logs.sql
-- Save profitable arbitrage opportunities to arbitrage_logs table

-- Insert only profitable opportunities (net profit > 0)
INSERT OR IGNORE INTO arbitrage_logs 
    (buy_ex_id, sell_ex_id, asset_id, buy_price, sell_price, gross_profit_pct, net_profit_pct, detected_at)
SELECT 
    e1.exchange_id,
    e2.exchange_id,
    1 AS asset_id,                            -- BTC
    m1.close_price,
    m2.close_price,
    ROUND((m2.close_price - m1.close_price) / m1.close_price * 100, 4) AS gross_pct,
    ROUND((m2.close_price - m1.close_price) / m1.close_price * 100 
          - (tf1.taker_fee + tf2.taker_fee) * 100, 4) AS net_pct,
    m1.trade_date
FROM market_data m1
JOIN market_data m2 ON m1.trade_date = m2.trade_date 
                   AND m1.exchange_id != m2.exchange_id
                   AND m2.close_price > m1.close_price
JOIN exchanges e1 ON m1.exchange_id = e1.exchange_id
JOIN exchanges e2 ON m2.exchange_id = e2.exchange_id
JOIN trading_fees tf1 ON m1.exchange_id = tf1.exchange_id
JOIN trading_fees tf2 ON m2.exchange_id = tf2.exchange_id
WHERE (m2.close_price - m1.close_price) / m1.close_price * 100 
      > (tf1.taker_fee + tf2.taker_fee) * 100;

-- Check how many rows were inserted
SELECT 'Profitable opportunities inserted' AS action, COUNT(*) AS count FROM arbitrage_logs;

-- Summary by exchange pair (most profitable combination)
SELECT 
    e1.exchange_name AS buy_exchange,
    e2.exchange_name AS sell_exchange,
    COUNT(*) AS total_opps,
    ROUND(AVG(net_profit_pct), 4) AS avg_net_pct,
    ROUND(MAX(net_profit_pct), 4) AS max_net_pct,
    ROUND(MIN(net_profit_pct), 4) AS min_net_pct
FROM arbitrage_logs al
JOIN exchanges e1 ON al.buy_ex_id = e1.exchange_id
JOIN exchanges e2 ON al.sell_ex_id = e2.exchange_id
GROUP BY e1.exchange_name, e2.exchange_name
ORDER BY avg_net_pct DESC;