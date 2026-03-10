
sudo wget https://github.com/prometheus/prometheus/releases/download/v3.5.1/prometheus-3.5.1.linux-amd64.tar.gz

sudo tar xvfz prometheus-3.5.1.linux-amd64.tar.gz

sudo mv prometheus-3.5.1.linux-amd64 /prometheus
sudo mkdir /var/lib/prometheus

cat << PROMETHEUS_FILE > prometheus/prometheus.yml

global:
  scrape_interval: 15s

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: "kafka-monitor"

scrape_configs:
  - job_name: "kafka-broker"

    scrape_interval: 5s

    static_configs:
      - targets:
          - kafka-broker-0:8091
          - kafka-broker-1:8091
          - kafka-broker-2:8091

        labels:
          env: "dev"

PROMETHEUS_FILE

sudo prometheus/prometheus --config.file=/prometheus/prometheus.yml
