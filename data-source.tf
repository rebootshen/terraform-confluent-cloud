# This file intentionally blank. You will create a `confluent_connector`
# resource here as part of the tutorial.

resource "confluent_schema" "orders_value" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id 
  }
  rest_endpoint = data.confluent_schema_registry_cluster.essentials.rest_endpoint

  subject_name = "${confluent_kafka_topic.orders.topic_name}-value"
  format       = "AVRO"
  schema       = file("${path.module}/orders-value.avsc")

  credentials {
    key    = confluent_api_key.schema_registry.id
    secret = confluent_api_key.schema_registry.secret
  }
}


resource "confluent_connector" "source" {
  environment {
    id = confluent_environment.tutorial.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.inventory.id
  }

  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "DatagenSourceConnector_0"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.orders_producer.id
    "kafka.topic"              = confluent_kafka_topic.orders.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "ORDERS"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_role_binding.orders_producer_write_to_topic,
    confluent_kafka_topic.orders,
    confluent_schema.orders_value,
  ]
}
