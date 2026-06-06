import sqlite3
import pandas as pd
from pathlib import Path


db_path = 'crypto_data.db'
conn = sqlite3.connect(db_path)


csv_files = {
    'binance': 'Binance_BTCUSDT_d.csv',
    'bitfinex': 'Bitfinex_BTCUSD_d.csv',
    'bitstamp': 'Bitstamp_BTCUSD_d.csv',
    'coinbase': 'COINBASE_BTCUSD.csv'
}

for exchange, filepath in csv_files.items():
    # Eğer dosya coinbase değilse ilk satırı (URL) atla, coinbase ise normal oku
    if exchange == 'coinbase':
        df = pd.read_csv(filepath)
    else:
        df = pd.read_csv(filepath, skiprows=1)
        
    table_name = f'{exchange}_prices'
    df.to_sql(table_name, conn, if_exists='replace', index=False)
    print(f'{table_name}: {len(df)} satır yüklendi')

conn.close()
print(f'\nVeritabanı başarıyla oluşturuldu: {db_path}')