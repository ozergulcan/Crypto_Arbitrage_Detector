# Multi-Exchange Crypto Arbitrage Detector 

A full-stack data engineering and financial analysis project built for the **MTM4692 Applied SQL** course. This project identifies real, profitable arbitrage opportunities across major cryptocurrency exchanges by analyzing historical price data and accounting for exchange-specific trading fees.

## Project Overview

Cryptocurrency prices can vary across different platforms. While these price differences (spreads) seem like immediate profit opportunities, transaction costs (maker/taker fees) often turn potential profits into losses. 

This system ingests raw market data from four major exchanges, cleans and standardizes it, and uses an SQLite database with advanced SQL views to calculate the **Net Profit** of transferring assets between exchanges. The results are visualized using a Flask-based web dashboard.

### Analyzed Exchanges
* Binance
* Coinbase
* Bitfinex
* Bitstamp

## Technologies Used
* **Database:** SQLite
* **Data Processing:** Python (Pandas), SQL
* **Backend:** Flask (Python)
* **Frontend:** HTML5, Bootstrap 5, Chart.js

##  Project Structure

\`\`\`text
Crypto_Arbitrage_Detector/
│
├── data/                       # Raw CSV data files from exchanges
├── sql/                        # SQL scripts for schema, cleaning, and analysis
│   ├── 01_create_schema.sql
│   ├── 03_clean_and_load.sql
│   ├── 04_arbitrage_analysis.sql
│   └── 05_save_logs.sql
├── templates/                  # Frontend HTML templates
│   └── index.html              # Dashboard UI
├── 02_load_data.py             # Python script for data ingestion
├── app.py                      # Flask web server and SQL connector
├── crypto_arbitrage.db         # Generated SQLite database
└── README.md                   # Project documentation
\`\`\`

##  Installation & Setup

Follow these steps to run the project locally:

**1. Clone the repository**
\`\`\`bash
git clone https://github.com/ozergulcan/Crypto_Arbitrage_Detector.git
cd Crypto_Arbitrage_Detector
\`\`\`

**2. Install required Python packages**
\`\`\`bash
pip install flask pandas
\`\`\`

**3. Initialize the database and load data**
Ensure your raw CSV files are inside the `data/` folder, then run the ingestion script:
\`\`\`bash
python 02_load_data.py
\`\`\`
*(Note: You must execute the SQL scripts in the `sql/` folder in numerical order to build the schema, clean the data, and create the analysis views.)*

**4. Run the Web Dashboard**
\`\`\`bash
python app.py
\`\`\`

**5. View the Dashboard**
Open your web browser and navigate to: `http://127.0.0.1:5000/`

## 👥 Team Members
* **Gülcan Özer** * **Ecem Demir**   ##  License
This project was developed for academic purposes as part of the MTM4692 Applied SQL curriculum.