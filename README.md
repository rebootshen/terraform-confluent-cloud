# Confluent Cloud with Terraform

Create a Confluent Cloud environment, a Standard Kafka cluster, an Avro schema, RBAC, and a Datagen source connector with the Confluent Terraform provider.

## What this shows

- Confluent provider 2.x authenticated with cloud API keys from the environment
- A Standard Kafka cluster, an Avro schema, and a Datagen source connector
- Separate admin, producer, and consumer service accounts, with role bindings limited to the `orders` topic, the CLI consumer groups, and the schema subject

## Architecture

```text
Confluent Cloud
└─ environment "tutorial" (Stream Governance Essentials)
   ├─ Schema Registry
   └─ Kafka cluster "inventory" (AWS us-east-2, single zone, Standard)
      ├─ topic "orders"
      ├─ Avro schema subject orders-value (orders-value.avsc)
      └─ Datagen source connector -> orders
   service accounts
      ├─ admin            CloudClusterAdmin, Kafka API key
      ├─ orders_producer  DeveloperWrite on the topic and schema subject
      └─ orders_consumer  DeveloperRead on the topic and CLI consumer groups
```

## Prerequisites

- Terraform >= 1.2
- Confluent CLI (`confluent login --save`)
- A Confluent Cloud API key for a service account that can create environments and clusters

Create that bootstrap identity outside Terraform. Replace `sa-xxxxxxxx` with the id printed by the create command. `OrganizationAdmin` is broader than this lab needs. Use it only on a personal organization, and delete the account when the lab is done.

```bash
confluent iam service-account create tf-cloud-admin \
  --description "Terraform Cloud API / OrganizationAdmin (lab only)"

confluent iam rbac role-binding create \
  --principal User:sa-xxxxxxxx \
  --role OrganizationAdmin

confluent api-key create \
  --resource cloud \
  --service-account sa-xxxxxxxx \
  --description "terraform confluent provider"
```

Export the key before Terraform runs. The provider reads these two variables.

```bash
export CONFLUENT_CLOUD_API_KEY="your-key"
export CONFLUENT_CLOUD_API_SECRET="your-secret"
```

## Quick start

```bash
terraform init
terraform plan
terraform apply
```

Read cluster coordinates from outputs. Keep live ids out of this repository.

```bash
ENV="$(terraform output -raw environment_id)"
CLUSTER="$(terraform output -raw kafka_cluster_id)"

confluent environment use "$ENV"
confluent kafka cluster use "$CLUSTER"
```

The Datagen connector writes Avro orders to the `orders` topic. To consume with the CLI, store the `orders_consumer` API key that Terraform created. `terraform state show` prints the secret as `(sensitive value)`. The value is still in local state; read it from the state JSON. Do not commit or paste that secret.

```bash
terraform state show confluent_api_key.orders_consumer

KEY="$(terraform state pull | jq -r '.resources[] | select(.type=="confluent_api_key" and .name=="orders_consumer") | .instances[0].attributes.id')"
SECRET="$(terraform state pull | jq -r '.resources[] | select(.type=="confluent_api_key" and .name=="orders_consumer") | .instances[0].attributes.secret')"

confluent api-key store "$KEY" "$SECRET" --resource "$CLUSTER"
confluent api-key use "$KEY" --resource "$CLUSTER"
confluent kafka topic consume orders --from-beginning
```

## Layout

| Path | Purpose |
|---|---|
| `terraform.tf` | Terraform >= 1.2 and `confluentinc/confluent` `~> 2.0`. |
| `main.tf` | Environment, Kafka cluster, service accounts, role bindings, API keys, and the `orders` topic. |
| `data-source.tf` | Avro schema and Datagen source connector. |
| `orders-value.avsc` | Avro schema registered as the `orders-value` subject. |
| `outputs.tf` | REST endpoint, environment id, and Kafka cluster id. |

## Tear down

```bash
terraform destroy
```

A Standard cluster is a billed Confluent Cloud resource. Destroy it when the lab is finished. Delete the bootstrap `tf-cloud-admin` service account in the Cloud console or with the CLI when you no longer need it.

## Notes

- This lab extends the HashiCorp tutorial [learn-terraform-confluent-provider](https://github.com/hashicorp-education/learn-terraform-confluent-provider) with Schema Registry RBAC and a Datagen source connector.
- `terraform.tfstate` and `*.tfvars` are gitignored. State contains API secrets.
- Do not commit API keys, live key ids, or environment and cluster ids.
- `config_sensitive` on the connector is empty because the connector authenticates as the `orders_producer` service account.
