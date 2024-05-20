provider "aws" {
  region = var.aws_region
}
module "generate-local-ssh-keys" {
  source    = "../resources/scripts/generate_local_ssh_keys"
  timestamp = local.timestamp
  keys_path = var.keys_path
}
module "vpc" {
  source              = "../resources/vpc"
  vpc_cidr            = var.vpc_cidr
  application_version = var.application_version
  timestamp           = local.timestamp
  creator             = local.creator
}

module "private_subnet" {
  source              = "../resources/private_subnet"
  application_version = var.application_version
  aws_storage_aw      = var.aws_storage_az
  creator             = local.creator
  timestamp           = local.timestamp
  private_subnet_cidr = var.private_subnet_cidr
  vpc_id              = module.vpc.vpc_id
  subnet_count        = length(var.private_subnet_cidr)
}

module "public_subnet" {
  source              = "../resources/public_subnet"
  application_version = var.application_version
  aws_storage_aw      = var.aws_storage_az[0]
  creator             = local.creator
  timestamp           = local.timestamp
  public_subnet_cidr  = var.public_subnet_cidr
  vpc_id              = module.vpc.vpc_id
}

module "external_security_group" {
  source              = "../resources/external_security_group"
  application_version = var.application_version
  creator             = local.creator
  timestamp           = local.timestamp
  vpc_id              = module.vpc.vpc_id
}

module "internal_security_group" {
  source              = "../resources/internal_security_group"
  application_version = var.application_version
  creator             = local.creator
  timestamp           = local.timestamp
  vpc_id              = module.vpc.vpc_id
  pods_cidr           = var.pods_cidr
  private_subnet_cidr = var.private_subnet_cidr
  subnet_count        = length(var.private_subnet_cidr)
}

module "internal_to_external_security_group" {
  source              = "../resources/internal_to_external_security_group"
  application_version = var.application_version
  creator             = local.creator
  timestamp           = local.timestamp
  vpc_id              = module.vpc.vpc_id
  public_subnet_cidr  = var.public_subnet_cidr
}

module "auto-generated-key-pairs" {
  source              = "../resources/key_pairs/auto_generated"
  application_version = var.application_version
  creator             = local.creator
  key_path            = var.key_path
  timestamp           = local.timestamp
  depends_on          = [module.generate-local-ssh-keys]
}


module "proxy-server" {
  source              = "../resources/proxy_server"
  ami                 = lookup(var.ami, "proxy")
  application_version = var.application_version
  creator             = local.creator
  instance_type       = lookup(var.instance_type, "proxy")
  key_id              = module.auto-generated-key-pairs.key-id
  security_group_ids  = [module.external_security_group.security_group_id]
  subnet_id           = module.public_subnet.subnet_id
  timestamp           = local.timestamp
}

module "installer-server" {
  source              = "../resources/installer_server"
  ami                 = lookup(var.ami, "installer")
  application_version = var.application_version
  creator             = local.creator
  instance_type       = lookup(var.instance_type, "installer")
  key_id              = module.auto-generated-key-pairs.key-id
  security_group_ids  = concat(module.internal_security_group.security_group_ids, [module.internal_to_external_security_group.security_group_id])
  subnet_id           = module.private_subnet.subnet_ids[0]
  timestamp           = local.timestamp
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
  instance_count      = var.co_res_count
  instance_type       = lookup(var.instance_type, "co-res")
  key_id              = module.auto-generated-key-pairs.key-id
  security_group_ids  = concat(module.internal_security_group.security_group_ids, [module.internal_to_external_security_group.security_group_id])
  subnet_ids          = module.private_subnet.subnet_ids
  timestamp           = local.timestamp
  disk_count          = var.number_of_disks
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
  subnet_ids             = module.private_subnet.subnet_ids
  target_group_port      = var.target_group_port
  target_group_protocol  = var.target_group_protocol
  timestamp              = local.timestamp
  vpc_id                 = module.vpc.vpc_id
  depends_on             = [module.co-res-server]
}

module "create-user-data-and-allow-access" {
  source             = "../resources/scripts/create_user_data_and_allow_access"
  count              = length(module.co-res-server.co_res_ips)
  generated_username = var.generated_username
  host_ip            = module.proxy-server.proxy_ip
  ssh_ip             = module.co-res-server.co_res_ips[count.index]
  key_location       = "${var.key_path}-${local.timestamp}"
  user               = var.user
  pub_key_location   = "${var.key_path}-${local.timestamp}.pub"
  depends_on         = [module.proxy-server, module.co-res-server, module.auto-generated-key-pairs]
}

module "remove-on-destroy" {
  source          = "../resources/scripts/remove_on_destroy"
  files_to_remove = module.generate-local-ssh-keys.output_files
}

