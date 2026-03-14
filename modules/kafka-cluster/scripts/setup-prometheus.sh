sudo wget https://github.com/prometheus/jmx_exporter/releases/download/1.5.0/jmx_prometheus_javaagent-1.5.0.jar
sudo mkdir -p /prometheus/rules

cat << 'PROMETHEUS_CONFIG' > ${prometheus_properties_path}
${ prometheus_properties }
PROMETHEUS_CONFIG
