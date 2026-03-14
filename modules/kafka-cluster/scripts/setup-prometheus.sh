sudo wget https://github.com/prometheus/jmx_exporter/releases/download/1.5.0/jmx_prometheus_javaagent-1.5.0.jar
sudo mkdir -p ${prometheus_dirname}

cat << 'PROMETHEUS_CONFIG' > ${prometheus_properties_filename}
${ prometheus_properties_content }
PROMETHEUS_CONFIG
