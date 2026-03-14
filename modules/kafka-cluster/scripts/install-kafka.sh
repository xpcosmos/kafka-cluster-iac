sudo wget https://dlcdn.apache.org/kafka/4.1.1/kafka_2.13-4.1.1.tgz
sudo tar -xzf /kafka_2.13-4.1.1.tgz
sudo mv /kafka_2.13-4.1.1 ${ kafka_home }
sudo rm -rf /kafka_2.13-4.1.1.tgz

sudo mkdir -p ${ log_dirs }
sudo chown -R $USER:$USER ${ log_dirs }