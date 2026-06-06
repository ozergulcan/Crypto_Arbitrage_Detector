# load_staging.py
# Python script to load CSV data into SQLite staging tables

import sqlite3
import csv
import os
from pathlib import Path

# Database file
DB_FILE = "crypto_arbitrage.db"

# Connect to SQLite database (creates if not exists)
conn = sqlite3.connect(DB_FILE)
cursor = conn.cursor()

def load_csv(csv_path, table_name, skip_rows=0, columns=None):
    """Load CSV file into SQLite table, skipping specified rows."""
    if not os.path.exists(csv_path):
        print(f"ERROR: File not found - {csv_path}")
        return False
    with open(csv_path, 'r', encoding='utf-8') as f:
        # Skip rows
        for _ in range(skip_rows):
            f.readline()
        reader = csv.reader(f)
        rows = list(reader)
        if not rows:
            print(f"WARNING: No data in {csv_path}")
            return False
        # If columns not provided, use all columns in order
        if columns is None:
            columns = [f"col{i}" for i in range(len(rows[0]))]
        placeholders = ','.join(['?' for _ in columns])
        col_names = ','.join(columns)
        sql = f"INSERT INTO {table_name} ({col_names}) VALUES ({placeholders})"
        try:
            cursor.executemany(sql, rows)
            conn.commit()
            print(f"SUCCESS: {table_name} - {len(rows)} rows inserted from {os.path.basename(csv_path)}")
            return True
        except Exception as e:
            print(f"ERROR inserting into {table_name}: {e}")
            return False

# Define expected columns for each staging table
staging_columns = {
    'staging_binance': ['unix_ts', 'date_raw', 'symbol', 'open', 'high', 'low', 'close', 'volume_btc', 'volume_usdt', 'tradecount'],
    'staging_bitfinex': ['unix_ts', 'date_raw', 'symbol', 'open', 'high', 'low', 'close', 'volume_usd', 'volume_btc'],
    'staging_bitstamp': ['unix_ts', 'date_raw', 'symbol', 'open', 'high', 'low', 'close', 'volume_btc', 'volume_usd'],
    'staging_coinbase': ['date_raw', 'open', 'high', 'low', 'close', 'volume', 'volume_ma']
}

# Clear staging tables before loading (optional)
def clear_staging_tables():
    for table in staging_columns.keys():
        cursor.execute(f"DELETE FROM {table}")
    conn.commit()
    print("Staging tables cleared.")

clear_staging_tables()

# Load each CSV
load_csv('data/Binance_BTCUSDT_d.csv', 'staging_binance', skip_rows=2, columns=staging_columns['staging_binance'])
load_csv('data/Bitfinex_BTCUSD_d.csv', 'staging_bitfinex', skip_rows=2, columns=staging_columns['staging_bitfinex'])
load_csv('data/Bitstamp_BTCUSD_d.csv', 'staging_bitstamp', skip_rows=2, columns=staging_columns['staging_bitstamp'])
load_csv('data/COINBASE_BTCUSD.csv', 'staging_coinbase', skip_rows=1, columns=staging_columns['staging_coinbase'])

# Verify row counts
print("\n--- Row counts after loading ---")
for table in staging_columns.keys():
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    count = cursor.fetchone()[0]
    print(f"{table}: {count} rows")

conn.close()
print("Loading completed.")