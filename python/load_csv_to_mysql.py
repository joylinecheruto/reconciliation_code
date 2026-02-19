import os
import time
import pandas as pd
import mysql.connector
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import logging

# ------------------------
# Logging setup
# ------------------------
logging.basicConfig(
    filename='etl_log.txt',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

# ------------------------
# MySQL Connection
# ------------------------
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='root',
    database='recon_25'
)
cursor = conn.cursor()

# ------------------------
# Folder to watch
# ------------------------
FOLDER_TO_WATCH = r"C:\Users\Joyli\OneDrive\RECONCILIATION"

# ------------------------
# Function to load CSV into MySQL (optimized)
# ------------------------
def load_csv_to_mysql(file_path):
    table_name = os.path.splitext(os.path.basename(file_path))[0]
    print(f"\nProcessing {file_path} → Table: {table_name}")
    logging.info(f"Processing {file_path} → Table: {table_name}")

    # ------------------------
    # Read CSV safely
    # ------------------------
    try:
        df = pd.read_csv(
            file_path,
            encoding="latin1",
            dtype=str,  # read as string first
            engine="python",
            keep_default_na=False
        )
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        logging.error(f"Error reading {file_path}: {e}")
        return

    if df.empty:
        print(f"{file_path} is empty, skipping.")
        logging.info(f"{file_path} is empty, skipping.")
        return

    df.columns = [col.strip() for col in df.columns]

    # ------------------------
    # Clean data
    # ------------------------
    for col in df.columns:
        df[col] = df[col].apply(lambda x: x.strip() if isinstance(x, str) else x)
        df[col] = df[col].replace({'': None})

    # ------------------------
    # Check if table exists
    # ------------------------
    cursor.execute("SHOW TABLES LIKE %s", (table_name,))
    exists = cursor.fetchone()

    if exists:
        # Faster than DROP + CREATE
        cursor.execute(f"TRUNCATE TABLE `{table_name}`")
        print(f"Truncated existing table `{table_name}`")
        logging.info(f"Truncated existing table `{table_name}`")
    else:
        # Create table
        cols_with_types = []
        for col in df.columns:
            try:
                temp = pd.to_numeric(df[col].dropna())
                col_type = "INT" if pd.api.types.is_integer_dtype(temp) else "FLOAT"
            except:
                col_type = "VARCHAR(255)"
            cols_with_types.append(f"`{col}` {col_type}")

        create_table_sql = f"CREATE TABLE `{table_name}` ({', '.join(cols_with_types)}) ENGINE=InnoDB;"
        try:
            cursor.execute(create_table_sql)
            print(f"Created table `{table_name}` successfully.")
            logging.info(f"Created table `{table_name}` successfully.")
        except Exception as e:
            print(f"Error creating table `{table_name}`: {e}")
            logging.error(f"Error creating table `{table_name}`: {e}")
            return

    # ------------------------
    # Insert data in chunks
    # ------------------------
    cols = ', '.join([f"`{c}`" for c in df.columns])
    placeholders = ', '.join(['%s'] * len(df.columns))
    chunk_size = 5000

    for start in range(0, len(df), chunk_size):
        chunk = df.iloc[start:start+chunk_size]
        data = [tuple(v if v != '' else None for v in row) for row in chunk.itertuples(index=False)]
        try:
            cursor.executemany(f"INSERT INTO `{table_name}` ({cols}) VALUES ({placeholders})", data)
            conn.commit()
        except Exception as e:
            print(f"Error inserting chunk into `{table_name}`: {e}")
            logging.error(f"Error inserting chunk into `{table_name}`: {e}")

    print(f"Loaded {len(df)} rows into `{table_name}`")
    logging.info(f"Loaded {len(df)} rows into `{table_name}`")

    # ------------------------
    # Export this table to CSV (optimized)
    # ------------------------
    export_table_to_csv(table_name)

# ------------------------
# Export a single table to CSV (optimized)
# ------------------------
def export_table_to_csv(table_name):
    csv_path = os.path.join(FOLDER_TO_WATCH, f"{table_name}.csv")
    if os.path.exists(csv_path):
        return  # Only export new table

    try:
        df = pd.read_sql(f"SELECT * FROM `{table_name}`", conn)
        if df.empty:
            return
        df = df.fillna('')  # replace NULLs with empty string
        for col in df.columns:
            df[col] = df[col].astype(str)  # ensure all columns are strings
        df.to_csv(csv_path, index=False, encoding='utf-8-sig', chunksize=5000)
        print(f"Exported new table `{table_name}` → {csv_path}")
        logging.info(f"Exported new table `{table_name}` → {csv_path}")
    except Exception as e:
        print(f"Error exporting `{table_name}`: {e}")
        logging.error(f"Error exporting `{table_name}`: {e}")

# ------------------------
# Process existing CSVs immediately
# ------------------------
existing_csvs = [
    f for f in os.listdir(FOLDER_TO_WATCH)
    if os.path.isfile(os.path.join(FOLDER_TO_WATCH, f)) and f.endswith(".csv")
]

if existing_csvs:
    for file in existing_csvs:
        load_csv_to_mysql(os.path.join(FOLDER_TO_WATCH, file))
else:
    print("No existing CSV files found in folder.")
    logging.info("No existing CSV files found in folder.")

# ------------------------
# Watchdog for new CSVs
# ------------------------
class ETLHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
        if event.src_path.endswith(".csv"):
            load_csv_to_mysql(event.src_path)

observer = Observer()
observer.schedule(ETLHandler(), FOLDER_TO_WATCH, recursive=False)
observer.start()
print(f"\nWatching folder: {FOLDER_TO_WATCH} for new CSV files...")
logging.info(f"Watching folder: {FOLDER_TO_WATCH} for new CSV files...")

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
    print("\nStopped by user.")
    logging.info("Stopped by user.")

observer.join()
cursor.close()
conn.close()
