
sudo wget https://github.com/prometheus/prometheus/releases/download/v3.5.1/prometheus-3.5.1.linux-amd64.tar.gz

sudo tar xvfz prometheus-3.5.1.linux-amd64.tar.gz
sudo mv prometheus-3.5.1.linux-amd64 /prometheus
sudo mkdir -p /var/lib/prometheus

cat << PROMETHEUS_FILE > /prometheus/prometheus.yml
${content}
PROMETHEUS_FILE

sudo prometheus/prometheus --config.file=/prometheus/prometheus.yml
