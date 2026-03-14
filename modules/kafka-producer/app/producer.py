from confluent_kafka import Producer
from delivery_tracking_simulator import DeliveryTrackingGenerator
from dataclasses import asdict
import json
import socket
import os
from dotenv import load_dotenv

load_dotenv()

count = 0

UPDATES_PER_SEC = 5
NUM_DRIVERS = 5

conf = {
    "bootstrap.servers": os.getenv("BOOTSTRAP_SERVERS"),
    "client.id": socket.gethostname(),
}

producer = Producer(conf)

tracking_gen = DeliveryTrackingGenerator(
    updates_per_sec=UPDATES_PER_SEC, num_drivers=NUM_DRIVERS
)

print(
    f"Starting Delivery Tracking Simulation for {NUM_DRIVERS} drivers at {UPDATES_PER_SEC} updates/sec... (Press Ctrl+C to stop)"
)
try:
    for pos in tracking_gen.generate_tracking_data():
        count += 1
        pos_dict = asdict(pos)
        producer.produce("teste", value=json.dumps(pos_dict), key=pos.driver_id)
        producer.flush()
        print(pos_dict)
except KeyboardInterrupt:
    print(f"\nSimulation stopped. {count} tracking updates generated.")