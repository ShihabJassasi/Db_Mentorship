import pandas as pd
import logging
import os

from sqlalchemy import create_engine, text
from dotenv import load_dotenv


# Configure the log file
logging.basicConfig(
    filename="../logs/raw_load.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)


# Load environment variables from .env file
load_dotenv()


# Read database connection settings
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")


# Create PostgreSQL connection
engine = create_engine(
    f"postgresql+psycopg2://{db_user}:{db_password}"
    f"@{db_host}:{db_port}/{db_name}"
)


# Test database connection
try:
    with engine.connect() as connection:
        database = connection.execute(
            text("SELECT current_database()")
        ).scalar()

        logging.info(
            f"Database connection successful: {database}"
        )

except Exception as e:
    logging.error(
        f"Database connection failed: {e}"
    )
    raise


# Start raw data loading
logging.info("Raw data loading started")


try:
    # Read customers CSV
    customers = pd.read_csv(
        "../Dataset/olist_customers_dataset.csv"
    )
    logging.info(
        f"Customers CSV loaded: {customers.shape[0]} rows"
    )


    # Read products CSV
    products = pd.read_csv(
        "../Dataset/olist_products_dataset.csv"
    )
    logging.info(
        f"Products CSV loaded: {products.shape[0]} rows"
    )


    # Read orders CSV
    orders = pd.read_csv(
        "../Dataset/olist_orders_dataset.csv"
    )
    logging.info(
        f"Orders CSV loaded: {orders.shape[0]} rows"
    )


    # Read order items CSV
    order_items = pd.read_csv(
        "../Dataset/olist_order_items_dataset.csv"
    )
    logging.info(
        f"Order Items CSV loaded: {order_items.shape[0]} rows"
    )


    # Load customers into Raw Layer
    customers.to_sql(
        "customers",
        engine,
        schema="raw_layer",
        if_exists="append",
        index=False
    )

    logging.info(
        f"Customers inserted: {customers.shape[0]} rows"
    )


    # Load products into Raw Layer
    products.to_sql(
        "products",
        engine,
        schema="raw_layer",
        if_exists="append",
        index=False
    )

    logging.info(
        f"Products inserted: {products.shape[0]} rows"
    )


    # Load orders into Raw Layer
    orders.to_sql(
        "orders",
        engine,
        schema="raw_layer",
        if_exists="append",
        index=False
    )

    logging.info(
        f"Orders inserted: {orders.shape[0]} rows"
    )


    # Load order items into Raw Layer
    order_items.to_sql(
        "order_items",
        engine,
        schema="raw_layer",
        if_exists="append",
        index=False
    )

    logging.info(
        f"Order Items inserted: {order_items.shape[0]} rows"
    )


    logging.info(
        "Raw data loaded into PostgreSQL successfully"
    )


except Exception as e:
    logging.error(
        f"Raw data loading failed: {e}"
    )
    raise