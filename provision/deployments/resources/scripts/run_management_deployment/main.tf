variable "host_ip" {
  type = string
  description = "the host ip to run the script on"
}
variable "user" {
  type = string
  description = "the login username on the host"
}
variable "key_location" {
  type = string
  description = "the path to the private key of the host"
}
variable "run_pfmp_deployment_location" {
  type = string
  description = "the path to the pfmp deployment script"
}
variable "pfmp_bundle_version" {
  type = string
  description = "the location and the version of the pfmp bundle on the server"
}
variable "installer_ip" {
  type = string
  description = "the installer private ip"
}
variable "management_ips" {
  type = list(string)
  description = "the list of management private ips"
}
resource "null_resource" "run-management-deployment" {
  connection {
    type        = "ssh"
    host        = var.host_ip
    user        = var.user
    private_key = file(var.key_location)
  }
  provisioner "file" {
    source      = var.run_pfmp_deployment_location
    destination = "/tmp/run_pfmp_deployment.sh"
  }
  provisioner "remote-exec" {
    inline = [
      // copy the background deployment script
      var.installer_ip != "" ?  "scp -o 'StrictHostKeyChecking no'  /tmp/run_pfmp_deployment.sh ${var.installer_ip}:/tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh" : "mv /tmp/run_pfmp_deployment.sh /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh",
      // ssh to installer and run the pfmp management installation in the background + output to /tmp/pfmp_management_deployment.log
      var.installer_ip != "" ?  "ssh -o 'StrictHostKeyChecking no' ${var.installer_ip} 'nohup dos2unix /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh && /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh ${join(" ",var.management_ips)} powerflex-denver-co-res &> /tmp/pfmp_management_deployment.log &' &" : "dos2unix /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh && chmod +x /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh && nohup /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh ${join(" ",var.management_ips)} powerflex-denver-co-res &> /tmp/pfmp_management_deployment.log &",
      "sleep 5"
    ]
  }
}