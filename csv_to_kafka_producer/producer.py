import csv
import json
import time
import os
from kafka import KafkaProducer
from kafka.errors import KafkaTimeoutError
from datetime import datetime

KAFKA_BROKER = os.getenv('KAFKA_BROKER_URL', 'kafka:9092')
KAFKA_TOPIC = 'source_events_v2' 
DATA_DIR = '/app/mock_data_csvs'

print(f"KAFKA_BROKER: {KAFKA_BROKER}")
print(f"KAFKA_TOPIC: {KAFKA_TOPIC}")
print(f"DATA_DIR: {DATA_DIR}")

def create_producer():
    retries = 0
    max_retries = 5
    while retries < max_retries:
        try:
            producer = KafkaProducer(
                bootstrap_servers=[KAFKA_BROKER],
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                linger_ms=100, 
                batch_size=16384 * 4, # 64KB
                acks='all',
                retries=3 
            )
            print("Kafka Producer connected successfully.")
            return producer
        except Exception as e:
            retries += 1
            print(f"Failed to connect to Kafka (attempt {retries}/{max_retries}): {e}. Retrying in 5 seconds...")
            time.sleep(5)
    print(f"Could not connect to Kafka after {max_retries} attempts. Exiting.")
    return None


def parse_date_flexible(date_str, formats=['%m/%d/%Y', '%Y-%m-%d']):
    if not date_str or date_str.strip() == '':
        return None
    for fmt in formats:
        try:
            dt_obj = datetime.strptime(date_str, fmt)
            return dt_obj.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z' 
        except ValueError:
            continue
    # print(f"Warning: Could not parse date string: '{date_str}' with known formats. Returning as is.")
    return date_str 

def try_parse_int(value, default=None):
    if value is None or str(value).strip() == '':
        return default
    try:
        return int(value)
    except ValueError:
        # print(f"Warning: Could not parse int: '{value}'. Returning default: {default}")
        return default

def try_parse_float(value, default=None):
    if value is None or str(value).strip() == '':
        return default
    try:
        return float(value)
    except ValueError:
        # print(f"Warning: Could not parse float: '{value}'. Returning default: {default}")
        return default

def send_data(producer, topic, data_files_dir):

    for i in range(1, 11):
        file_path = os.path.join(data_files_dir, f'mock_data_{i}.csv')
        if not os.path.exists(file_path):
            print(f"File {file_path} not found. Skipping.")
            continue

        print(f"Processing file: {file_path}")
        with open(file_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            count = 0
            for row_raw in reader:
                row = dict(row_raw) 

                try:
                    row['id'] = try_parse_int(row.get('id'))
                    row['customer_age'] = try_parse_int(row.get('customer_age'))
                    
                    row['product_price'] = try_parse_float(row.get('product_price'))
                    row['product_quantity'] = try_parse_int(row.get('product_quantity')) 
                    
                    row['sale_date'] = parse_date_flexible(row.get('sale_date')) 
                    
                    row['sale_customer_id'] = try_parse_int(row.get('sale_customer_id'))
                    row['sale_seller_id'] = try_parse_int(row.get('sale_seller_id'))
                    row['sale_product_id'] = try_parse_int(row.get('sale_product_id'))
                    row['sale_quantity'] = try_parse_int(row.get('sale_quantity')) 
                    row['sale_total_price'] = try_parse_float(row.get('sale_total_price'))
                    
                    row['product_weight'] = try_parse_float(row.get('product_weight'))
                    row['product_rating'] = try_parse_float(row.get('product_rating'))
                    row['product_reviews'] = try_parse_int(row.get('product_reviews'))
                    
                    row['product_release_date'] = parse_date_flexible(row.get('product_release_date'))
                    row['product_expiry_date'] = parse_date_flexible(row.get('product_expiry_date'))

                    for key, value in row.items():
                        if isinstance(value, str) and value.strip() == '':
                            row[key] = None
                        elif value is None: 
                             row[key] = None


                except Exception as e:
                    print(f"Error processing row data: {row_raw} - {e}. Skipping.")
                    continue 
                
                try:
                    producer.send(topic, row)
                    count += 1
                    if count % 200 == 0:
                        print(f"Sent {count} messages from {file_path}...")
                except KafkaTimeoutError:
                    print(f"Kafka send timeout for row: {row}. Retrying send...")
                    time.sleep(1) 
                    try:
                        producer.send(topic, row) 
                    except Exception as e_retry:
                        print(f"Retry failed for row {row}: {e_retry}")
                except Exception as e:
                    print(f"Error sending message to Kafka: {row} - {e}")
            
            producer.flush() 
            print(f"Finished processing {file_path}. Sent {count} messages.")
        # time.sleep(1) 

if __name__ == "__main__":
    if not os.path.exists(os.path.join(DATA_DIR, 'mock_data_1.csv')):
        print(f"ERROR: Mock data not found in {DATA_DIR}. Please ensure CSV files are present.")
        print(f"Current working directory: {os.getcwd()}")
        print(f"Contents of DATA_DIR ('{DATA_DIR}'): {os.listdir(DATA_DIR) if os.path.exists(DATA_DIR) else 'Not found'}")
        exit(1)
        
    kafka_producer = create_producer()
    if kafka_producer:
        print("Starting to send data...")
        send_data(kafka_producer, KAFKA_TOPIC, DATA_DIR)
        kafka_producer.close()
        print("All data sent and producer closed.")
    else:
        print("Could not create Kafka producer after multiple retries. Exiting.")