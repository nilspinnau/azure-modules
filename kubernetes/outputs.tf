output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.name
}

output "kube_config_raw" {
  description = "Raw Kubernetes config"
  value       = azurerm_kubernetes_cluster.default.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw Kubernetes admin config"
  value       = azurerm_kubernetes_cluster.default.kube_admin_config_raw
  sensitive   = true
}

output "host" {
  description = "The Kubernetes cluster server host"
  value       = azurerm_kubernetes_cluster.default.kube_config.0.host
  sensitive   = true
}

output "client_certificate" {
  description = "The client certificate for authenticating to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.default.kube_config.0.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "The client key for authenticating to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.default.kube_config.0.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "kubelet_identity" {
  description = "The managed identity used by the kubelet"
  value       = azurerm_kubernetes_cluster.default.kubelet_identity
}

output "identity" {
  description = "The identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.identity
}

output "node_resource_group" {
  description = "The resource group where the Kubernetes nodes are deployed"
  value       = azurerm_kubernetes_cluster.default.node_resource_group
}