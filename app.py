from flask import Flask, render_template
import sqlite3

app = Flask(__name__)
DB_FILE = "crypto_arbitrage.db"

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

@app.route("/")
def index():
    conn = get_db_connection()
    
    # ----- 1. Arbitraj fırsatlarını doğrudan market_data ve trading_fees ile hesapla -----
    # (arbitrage_view'e gerek yok)
    arbitrage_query = """
    WITH price_pairs AS (
        SELECT 
            m1.trade_date,
            e1.exchange_name AS buy_exchange,
            e2.exchange_name AS sell_exchange,
            m1.close_price AS buy_price,
            m2.close_price AS sell_price,
            (m2.close_price - m1.close_price) / m1.close_price * 100 AS gross_profit_pct,
            tf1.taker_fee AS buy_fee,
            tf2.taker_fee AS sell_fee
        FROM market_data m1
        JOIN market_data m2 ON m1.trade_date = m2.trade_date
        JOIN exchanges e1 ON m1.exchange_id = e1.exchange_id
        JOIN exchanges e2 ON m2.exchange_id = e2.exchange_id
        JOIN trading_fees tf1 ON m1.exchange_id = tf1.exchange_id
        JOIN trading_fees tf2 ON m2.exchange_id = tf2.exchange_id
        WHERE m1.exchange_id != m2.exchange_id
          AND m2.close_price > m1.close_price
    )
    SELECT 
        trade_date,
        buy_exchange,
        sell_exchange,
        buy_price,
        sell_price,
        ROUND(gross_profit_pct, 4) AS gross_profit_pct,
        ROUND(gross_profit_pct - (buy_fee + sell_fee) * 100, 4) AS net_profit_pct
    FROM price_pairs
    ORDER BY net_profit_pct DESC
    LIMIT 100
    """
    opportunities = conn.execute(arbitrage_query).fetchall()
    
    # ----- 2. KPI metrikleri (sadece kârlı olanlar) -----
    kpi_query = """
    WITH price_pairs AS (
        SELECT 
            m1.trade_date,
            e1.exchange_name AS buy_exchange,
            e2.exchange_name AS sell_exchange,
            (m2.close_price - m1.close_price) / m1.close_price * 100 AS gross_profit_pct,
            tf1.taker_fee AS buy_fee,
            tf2.taker_fee AS sell_fee
        FROM market_data m1
        JOIN market_data m2 ON m1.trade_date = m2.trade_date
        JOIN exchanges e1 ON m1.exchange_id = e1.exchange_id
        JOIN exchanges e2 ON m2.exchange_id = e2.exchange_id
        JOIN trading_fees tf1 ON m1.exchange_id = tf1.exchange_id
        JOIN trading_fees tf2 ON m2.exchange_id = tf2.exchange_id
        WHERE m1.exchange_id != m2.exchange_id
          AND m2.close_price > m1.close_price
    ),
    profitable AS (
        SELECT 
            gross_profit_pct - (buy_fee + sell_fee) * 100 AS net_profit_pct
        FROM price_pairs
        WHERE gross_profit_pct > (buy_fee + sell_fee) * 100
    )
    SELECT 
        COUNT(*) as total_count,
        ROUND(MAX(net_profit_pct), 4) as max_profit,
        ROUND(AVG(net_profit_pct), 4) as avg_profit
    FROM profitable
    """
    kpi_res = conn.execute(kpi_query).fetchone()
    kpis = {
        "total_opportunities": kpi_res["total_count"] if kpi_res["total_count"] else 0,
        "max_net_profit": kpi_res["max_profit"] if kpi_res["max_profit"] else 0,
        "avg_net_profit": kpi_res["avg_profit"] if kpi_res["avg_profit"] else 0
    }
    
    # ----- 3. En iyi arbitraj rotaları (en sık kârlı çift) -----
    best_routes_query = """
    WITH price_pairs AS (
        SELECT 
            e1.exchange_name AS buy_exchange,
            e2.exchange_name AS sell_exchange,
            (m2.close_price - m1.close_price) / m1.close_price * 100 AS gross_profit_pct,
            tf1.taker_fee AS buy_fee,
            tf2.taker_fee AS sell_fee
        FROM market_data m1
        JOIN market_data m2 ON m1.trade_date = m2.trade_date
        JOIN exchanges e1 ON m1.exchange_id = e1.exchange_id
        JOIN exchanges e2 ON m2.exchange_id = e2.exchange_id
        JOIN trading_fees tf1 ON m1.exchange_id = tf1.exchange_id
        JOIN trading_fees tf2 ON m2.exchange_id = tf2.exchange_id
        WHERE m1.exchange_id != m2.exchange_id
          AND m2.close_price > m1.close_price
          AND gross_profit_pct > (buy_fee + sell_fee) * 100
    )
    SELECT 
        buy_exchange,
        sell_exchange,
        COUNT(*) AS opp_count
    FROM price_pairs
    GROUP BY buy_exchange, sell_exchange
    ORDER BY opp_count DESC
    LIMIT 5
    """
    best_routes = conn.execute(best_routes_query).fetchall()
    
    # ----- 4. Borsa komisyon oranları -----
    fees_query = """
    SELECT e.exchange_name, tf.taker_fee, tf.maker_fee
    FROM trading_fees tf
    JOIN exchanges e ON tf.exchange_id = e.exchange_id
    """
    fees = conn.execute(fees_query).fetchall()
    
    # ----- 5. Grafik verisi (en iyi rotalar) -----
    chart_labels = [f"{r['buy_exchange']} → {r['sell_exchange']}" for r in best_routes]
    chart_values = [r['opp_count'] for r in best_routes]
    
    conn.close()
    
    return render_template(
        "index.html",
        opportunities=opportunities,
        kpis=kpis,
        best_routes=best_routes,
        fees=fees,
        chart_labels=chart_labels,
        chart_values=chart_values
    )

if __name__ == "__main__":
    app.run(debug=True, port=5000)