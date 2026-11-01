output "environment_id" {
  value = confluent_environment.tutorial.id
}

output "kafka_cluster_id" {
  value = confluent_kafka_cluster.inventory.id
}

output "inventory_cluster_rest_endpoint" {
  value = confluent_kafka_cluster.inventory.rest_endpoint
}
