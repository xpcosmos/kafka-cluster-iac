sudo apt update
sudo apt install python3 -y
sudo mkdir -p /app

sudo python3 -m pip install -r /app/requirements.txt
python3 /app/delivery_tracking_simulator.py