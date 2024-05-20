provider "aws" {
  region = var.aws_region
}

module "generate-local-ssh-keys" {
  source    = "../resources/scripts/generate_local_ssh_keys"
  timestamp = local.timestamp
  keys_path = var.keys_path
}

data "local_file" "private_key" {
  filename = "${var.keys_path}/powerflex-denver-key-${local.timestamp}"
  depends_on = [module.generate-local-ssh-keys]
}

data "template_file" "user_data" {
  template = file(var.user_data_path)
  vars = {
    private_key = data.local_file.private_key.content
  }
}

module "internal_security_group" {
  source              = "../resources/internal_security_group"
  application_version = var.application_version
  creator             = local.creator
  timestamp           = local.timestamp
  vpc_id              = var.vpc_id
  pods_cidr           = var.pods_cidr
  private_subnet_cidr = var.private_subnet_cidr
  subnet_count        = length(var.private_subnet_cidr)
}

module "auto-generated-key-pairs" {
  source              = "../resources/key_pairs/auto_generated"
  application_version = var.application_version
  creator             = local.creator
  key_path            = var.key_path
  timestamp           = local.timestamp
  depends_on          = [module.generate-local-ssh-keys]
}

module "installer-server" {
  source              = "../resources/installer_server"
  ami                 = lookup(var.ami, "installer")
  application_version = var.application_version
  creator             = local.creator
  instance_type       = lookup(var.instance_type, "installer")
  key_id              = module.auto-generated-key-pairs.key-id
  security_group_ids  = concat(module.internal_security_group.security_group_ids, [var.vpn_security_group])
  subnet_id           = var.subnet_ids[0]
  timestamp           = local.timestamp
  user_data           = data.template_file.user_data.rendered
  depends_on          = [module.auto-generated-key-pairs, module.internal_security_group]
}

module "co-res-disk" {
  source              = "../resources/co_res_disk"
  application_version = var.application_version
  aws_storage_az      = var.aws_storage_az
  creator             = local.creator
  disk_count          = var.number_of_disks
  disk_size           = var.disk_size
  instance_count      = var.co_res_count
  timestamp           = local.timestamp
}

module "co-res-server" {
  source              = "../resources/co_res_server"
  ami                 = lookup(var.ami, "co-res")
  application_version = var.application_version
  aws_storage_az      = var.aws_storage_az
  creator             = local.creator
  disk_count          = var.number_of_disks
  root_volume_size    = var.root_co-res_volume_size
  instance_count      = var.co_res_count
  instance_type       = lookup(var.instance_type, "co-res")
  key_id              = module.auto-generated-key-pairs.key-id
  security_group_ids  = concat(module.internal_security_group.security_group_ids, [var.vpn_security_group])
  subnet_ids          = var.subnet_ids
  timestamp           = local.timestamp
  user_data           = data.template_file.user_data.rendered
  volume_ids          = module.co-res-disk.volume_ids
}

module "load-balancer" {
  source                 = "../resources/load_balancer"
  application_version    = var.application_version
  cluster_node_port      = var.cluster_node_port
  creator                = local.creator
  load_balancer_port     = var.load_balancer_port
  load_balancer_protocol = var.load_balancer_protocol
  management_ids         = module.co-res-server.management_ids
  subnet_ids             = var.subnet_ids
  target_group_port      = var.target_group_port
  target_group_protocol  = var.target_group_protocol
  timestamp              = local.timestamp
  vpc_id                 = var.vpc_id
  depends_on             = [module.co-res-server]
}

module "run-new-installer-api" {
  source                         = "../resources/scripts/run_new_installer_api"
  co_res_ips                     = module.co-res-server.co_res_ips
  csv_template_path              = var.csv_template_path
  installer_ip                   = module.installer-server.installer_ip
  key_location                   = "${var.key_path}-${local.timestamp}"
  management_ips                 = module.co-res-server.management_ips
  run_new_installer_scripts_path = var.run_new_installer_scripts_path
  loadbalancer_dns               = module.load-balancer.loadbalancer_dns
  interpreter                    = var.interpreter
  relative_location              = var.relative_location
  timestamp                      = local.timestamp
  depends_on                     = [module.co-res-server, module.installer-server, module.load-balancer]
}

module "remove-on-destroy" {
  source          = "../resources/scripts/remove_on_destroy"
  files_to_remove = concat([module.run-new-installer-api.output_directory], module.generate-local-ssh-keys.output_files)
}

