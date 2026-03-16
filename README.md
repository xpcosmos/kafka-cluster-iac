# Infraestrutura de Cluster Kafka no GCP

Este projeto contém as configurações do Terraform para provisionar um cluster Apache Kafka totalmente monitorado no Google Cloud Platform (GCP). Ele inclui um ecossistema completo para produção, consumo e observabilidade de métricas do Kafka, desenvolvido para um projeto de pós-graduação (`projeto-kafka-pos`).

## Visão Geral da Arquitetura

![arquitetura](docs/source.png)

A infraestrutura implantada por esta configuração inclui os seguintes componentes:

- **Cluster Kafka**: Um cluster Kafka multinó configurável (padrão: 3 nós).
- **Kafka Connect & Redis Sink**: Integração para enviar (sink) dados para o Redis.
- **Kafka Producer App**: Um aplicativo de exemplo atuando como produtor e enviando dados para o cluster.
- **Servidor Redis**: Atua como o destino de sink para o Kafka Connect.
- **Prometheus**: Coleta métricas dos brokers Kafka e das instâncias do Connect.
- **Grafana**: Visualiza as métricas por meio de dashboards pré-provisionados.

Todos os recursos são criados dentro de uma rede dedicada (VPC) do GCP (`kafka-network`) com as respectivas regras de firewall definidas em `network.firewall.tf`.

## Pré-requisitos

Antes de aplicar esta configuração do Terraform, certifique-se de ter o seguinte:

- [Terraform](https://www.terraform.io/downloads.html) instalado.
- [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) instalado e autenticado.
- Um Projeto criado e configurado no GCP (padrão: `projeto-kafka-pos`).
- Chaves SSH configuradas no diretório `.keys/` (ex: `keys` e `keys.pub`) para acesso e provisionamento das VMs (através dos módulos como do Grafana).

## Uso

### 1. Clone o repositório e acesse o diretório
```bash
git clone https://github.com/xpcosmos/kafka-cluster-iac.git
cd kafka-cluster-iac
```

### 2. Inicialize o Terraform
Baixa o provider necessário `hashicorp/google` (v6.8.0) e inicializa o diretório de trabalho.
```bash
terraform init
```

### 3. Revise o plano de execução
Visualize os recursos que serão criados. Você pode sobrescrever variáveis como `project_id`, `cluster_size` ou a região do GCP no arquivo `variables.tf` ou através de flags na linha de comando.
```bash
terraform plan
```

### 4. Aplique a infraestrutura
Provisione os recursos no GCP.
```bash
terraform apply
```

### 5. Acessando os Serviços
Após a aplicação, o Terraform exibirá os endereços IP externos:
- `instance_external_ip`: IP Público do Prometheus.
- `external_ip_address_grafana`: IP Público do Grafana.

Você pode acessar o Grafana e o Prometheus por meio do navegador web, utilizando esses IPs públicos fornecidos.

## Estrutura do Projeto

- `compute_engine.tf`: Define todas as instâncias do GCP Compute Engine e invoca os módulos relevantes das aplicações (`kafka_cluster_server`, `grafana`, `prometheus`, `redis_server`, `kafka_producer_app`).
- `network.tf`: Define a rede VPC (`kafka-network`) e os IPs estáticos externos.
- `network.firewall.tf`: Configura as regras de firewall para acesso interno/externo às VMs.
- `provider.tf`: Configura o provider do Google (`us-central1`).
- `variables.tf`: Contém as configurações genéricas fornecidas e configurações de tópicos.
- `terraform.tfstate` / `terraform.tfstate.backup`: Arquivos de estado local do Terraform.
- `modules/`: Contém os módulos reutilizáveis do Terraform para cada componente específico.
- `grafana/`: Contém os dashboards do Grafana pré-configurados que são mapeados na inicialização da instância.

## Cleanup

Para evitar cobranças indesejadas no GCP, destrua toda a infraestrutura criada quando concluir seus testes:

```bash
terraform destroy
```
