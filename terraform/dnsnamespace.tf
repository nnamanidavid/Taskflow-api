resource "aws_service_discovery_private_dns_namespace" "taskflow" {
  name = "taskflow.local"
  vpc  = aws_vpc.taskflow_vpc.id
}



resource "aws_service_discovery_service" "taskflow_api" {
  name = "taskflow-api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.taskflow.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  #health_check_custom_config {

}