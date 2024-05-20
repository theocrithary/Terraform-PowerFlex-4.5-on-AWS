variable "vpc_id" {
  type = string
  description = "the vpc id"
}
variable "creator" {
  type = string
  description = "the script aws user initiator"
}
variable "timestamp" {
  type = string
  description = "the current timestamp"
}
variable "application_version" {
  type = string
  description = "the powerflex application_version name"
}
variable "management_ids" {
  type = list(string)
  description = "the management ids array"
}
variable "cluster_node_port" {
  type = string
  description = "the node port on the k8s cluster for client requests"
}
variable "subnet_ids" {
  type = list(string)
  description = "the load balancer subnet ids (private subnets)"
}
variable "load_balancer_port" {
  type = string
  description = "the load balancer listener port"
}
variable "load_balancer_protocol" {
  type = string
  description = "the load balancer listener protocol"
}
variable "target_group_port" {
  type = string
  description = "the target group listener port"
}
variable "target_group_protocol" {
  type = string
  description = "the target group listener protocol"
}
resource "aws_lb_target_group" "powerflex-network-lb-target-group" {
  name     = "${var.creator}-${var.timestamp}"
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id = var.vpc_id
  tags     = {
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    TimeStamp   = var.timestamp
    Creator     = var.creator
  }
}

resource "aws_lb_target_group_attachment" "powerflex-network-lb-target-group-attachment" {
  count            = length(var.management_ids)
  target_group_arn = aws_lb_target_group.powerflex-network-lb-target-group.arn
  target_id        = var.management_ids[count.index]
  port             = var.cluster_node_port
}

resource "aws_lb" "powerflex-network-lb" {
  name                       = "${var.creator}-${var.timestamp}"
  internal                   = true
  load_balancer_type         = "network"
  enable_deletion_protection = false
  subnets                    = var.subnet_ids
  tags = {
    Name        = "${var.application_version}-nlb-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    TimeStamp   = var.timestamp
    Creator     = var.creator
  }
}

resource "aws_lb_listener" "powerflex-lb-listener" {
  load_balancer_arn = aws_lb.powerflex-network-lb.arn
  port              = var.load_balancer_port
  protocol          = var.load_balancer_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.powerflex-network-lb-target-group.arn
  }
}

output "loadbalancer_dns" {
  description = "The dns domain name of the loadbalancer"
  value       =  try(aws_lb.powerflex-network-lb.dns_name, "")
}