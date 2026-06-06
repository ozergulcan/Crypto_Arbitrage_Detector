-- SQLite schema for crypto arbitrage detector

CREATE TABLE IF NOT EXISTS exchanges (
    exchange_id INTEGER PRIMARY KEY AUTOINCREMENT,
    exchange_name TEXT NOT NULL UNIQUE,
    location TEXT,
    reliability_score REAL
);

CREATE TABLE IF NOT EXISTS assets (
    asset_id INTEGER PRIMARY KEY AUTOINCREMENT,
    asset_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS market_data (
    data_id INTEGER PRIMARY KEY AUTOINCREMENT,
    exchange_id INTEGER NOT NULL,
    asset_id INTEGER NOT NULL,
    open_price REAL,
    high_price REAL,
    low_price REAL,
    close_price REAL NOT NULL,
    volume_btc REAL,
    trade_date TEXT NOT NULL,
    FOREIGN KEY (exchange_id) REFERENCES exchanges(exchange_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    UNIQUE(exchange_id, asset_id, trade_date)
);

CREATE TABLE IF NOT EXISTS trading_fees (
    fee_id INTEGER PRIMARY KEY AUTOINCREMENT,
    exchange_id INTEGER NOT NULL UNIQUE,
    maker_fee REAL NOT NULL,
    taker_fee REAL NOT NULL,
    withdrawal_fee REAL,
    FOREIGN KEY (exchange_id) REFERENCES exchanges(exchange_id)
);

CREATE TABLE IF NOT EXISTS arbitrage_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    buy_ex_id INTEGER NOT NULL,
    sell_ex_id INTEGER NOT NULL,
    asset_id INTEGER NOT NULL,
    buy_price REAL NOT NULL,
    sell_price REAL NOT NULL,
    gross_profit_pct REAL,
    net_profit_pct REAL,
    detected_at TEXT NOT NULL,
    FOREIGN KEY (buy_ex_id) REFERENCES exchanges(exchange_id),
    FOREIGN KEY (sell_ex_id) REFERENCES exchanges(exchange_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id)
);

-- Staging tables (raw CSV data)
CREATE TABLE IF NOT EXISTS staging_binance (
    unix_ts INTEGER,
    date_raw TEXT,
    symbol TEXT,
    open TEXT,
    high TEXT,
    low TEXT,
    close TEXT,
    volume_btc TEXT,
    volume_usdt TEXT,
    tradecount TEXT
);

CREATE TABLE IF NOT EXISTS staging_bitfinex (
    unix_ts INTEGER,
    date_raw TEXT,
    symbol TEXT,
    open TEXT,
    high TEXT,
    low TEXT,
    close TEXT,
    volume_usd TEXT,
    volume_btc TEXT
);

CREATE TABLE IF NOT EXISTS staging_bitstamp (
    unix_ts INTEGER,
    date_raw TEXT,
    symbol TEXT,
    open TEXT,
    high TEXT,
    low TEXT,
    close TEXT,
    volume_btc TEXT,
    volume_usd TEXT
);

CREATE TABLE IF NOT EXISTS staging_coinbase (
    date_raw TEXT,
    open TEXT,
    high TEXT,
    low TEXT,
    close TEXT,
    volume TEXT,
    volume_ma TEXT
);

-- Insert reference data
INSERT OR IGNORE INTO exchanges (exchange_id, exchange_name, location, reliability_score) VALUES
    (1, 'Binance', 'Cayman Islands', 9.0),
    (2, 'Coinbase', 'USA', 9.5),
    (3, 'Bitfinex', 'British Virgin Islands', 7.5),
    (4, 'Bitstamp', 'Luxembourg', 8.5);

INSERT OR IGNORE INTO assets (asset_id, asset_name) VALUES (1, 'BTC');

INSERT OR IGNORE INTO trading_fees (exchange_id, maker_fee, taker_fee, withdrawal_fee) VALUES
    (1, 0.0010, 0.0010, 0.0005),
    (2, 0.0040, 0.0060, 0.0000),
    (3, 0.0010, 0.0020, 0.0004),
    (4, 0.0030, 0.0050, 0.0005);

-- Verification
SELECT 'Exchanges' as table_name, COUNT(*) as count FROM exchanges
UNION ALL
SELECT 'Assets', COUNT(*) FROM assets
UNION ALL
SELECT 'TradingFees', COUNT(*) FROM trading_fees;