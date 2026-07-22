from pathlib import Path
import os
import logging


import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Suppress all logging
logging.disable(logging.CRITICAL)

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
db_engine = create_engine(DATABASE_URL)

DATA_DIR = Path("data")


def load_table(csv_file, table_name):
    try:
        df = pd.read_csv(DATA_DIR / csv_file)

        # Convert date columns if they exist
        if 'transaction_date' in df.columns:
            df['transaction_date'] = pd.to_datetime(df['transaction_date'])
        
        print(f"\nLoading {csv_file}...")
        print(f"Rows: {len(df)}")

        with db_engine.begin() as connection:
            connection.execute(
                text(f"TRUNCATE TABLE raw_schema.{table_name} CASCADE;")
            )

        df.to_sql(
            name=table_name,
            con=db_engine,
            schema="raw_schema",
            if_exists="append",
            index=False,
            method="multi",
            chunksize=1000,
        )

        with db_engine.connect() as connection:
            count = connection.execute(
                text(f"SELECT COUNT(*) FROM raw_schema.{table_name}")
            ).scalar()

        print(f"[OK] {table_name}: {count} rows loaded")
    except Exception as e:
        print(f"[ERROR] Error loading {table_name}: {type(e).__name__}")
        print(f"Message: {str(e)}")
        raise


load_table("country.csv", "country")
load_table("customer.csv", "customer")
load_table("product.csv", "product")
load_table("sales_transactions.csv", "sales_transactions")