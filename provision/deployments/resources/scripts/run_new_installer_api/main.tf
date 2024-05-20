variable "key_location" {
  type = string
  description = "the path to the private key of the host"
}
variable "co_res_ips" {
  type = list(string)
  description = "the list of co-res private ips"
}
variable "management_ips" {
  type = list(string)
  description = "the list of mno private ips"
}
variable "installer_ip" {
  type = string
  description = "the installer private ip"
}
variable "run_new_installer_scripts_path" {
  type = string
  description = "the path to the new run new installer scripts"
}
variable "csv_template_path" {
  type = string
  description = "the path to the core csv template"
}
variable "loadbalancer_dns" {
  type = string
  description = "the load balancer dns domain name"
}
variable "interpreter" {
  type = list(string)
  description = "the interpreter of this script"
}
variable "relative_location" {
  type = string
  description = "the relative location of the working dir"
}
variable "timestamp" {
  type = string
  description = "current timestamp of the deployment script"
}

resource "null_resource" "run_new_installer_api" {
  provisioner "local-exec" {
    working_dir = "${path.module}${var.relative_location}"
    interpreter = var.interpreter
    command = <<-EOT
      export LANG=C.UTF-8
      mkdir ./run-installer-scripts-${var.timestamp}
      cp -r ${var.run_new_installer_scripts_path}/* ./run-installer-scripts-${var.timestamp}
      cp ${var.csv_template_path} ./run-installer-scripts-${var.timestamp}/CSV_basic.csv
      dos2unix ./run-installer-scripts-${var.timestamp}/*
      chmod +x ./run-installer-scripts-${var.timestamp}/*
      cd ./run-installer-scripts-${var.timestamp} && ./convert_csv_to_ips.sh ${join(" ",var.co_res_ips)}
      ./create_rest_config_json.sh ${var.installer_ip} ${join(" ",var.management_ips)} ${var.loadbalancer_dns}
      cd ../ && rm -rf ./run-installer-scripts-${var.timestamp}/convert_csv_to_ips.sh ./run-installer-scripts-${var.timestamp}/create_rest_config_json.sh ./run-installer-scripts-${var.timestamp}/CSV_basic.csv ./run-installer-scripts-${var.timestamp}/PF_Installer_template.json ./run-installer-scripts-${var.timestamp}/core_deployment.csv
    EOT
  }
}

output "output_directory" {
  description = "The location of the output directory"
  value       =  "${path.module}${var.relative_location}run-installer-scripts-${var.timestamp}"
}