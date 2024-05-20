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
variable "reset_core_location" {
  type = string
  description = "the path to the reset core directory location"
}
variable "co_res_ips" {
  type = list(string)
  description = "the list of co-res private ips"
}
variable "loadbalancer_dns" {
  type = string
  description = "the load balancer dns domain name"
  default = ""
}
variable "installer_ip" {
  type = string
  description = "the installer private ip"
  default = ""
}
variable "generated_username" {
  type = string
  description = "the username to generate on the servers"
}
/**
holds the reset core scripts + loadbalancer ip as env variable
*/
resource "null_resource" "custom-cluster-scripts" {
  connection {
    type        = "ssh"
    host        = var.host_ip
    user        = var.user
    private_key = file(var.key_location)
  }

  provisioner "file" {
    source      = var.reset_core_location
    destination = "/tmp/reset-core-installation"
  }
  provisioner "remote-exec" {
    inline = [
      // convert files to linux encoding
      "dos2unix /tmp/reset-core-installation/*",
      // create the post deployment directory in the installer
      var.installer_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.installer_ip} 'mkdir -p /tmp/bundle/post_deployment_scripts'" : "mkdir -p /tmp/bundle/post_deployment_scripts",
      // update the core deployment csv with the servers ip's
      "chmod +x /tmp/reset-core-installation/*",
      // update the reset core scripts with the servers ip's
      "cd /tmp/reset-core-installation && ./build-clean-core-mno.sh ${join(" ",var.co_res_ips)}",
      // update the installer server with all the relevant scripts
      var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' -r /tmp/reset-core-installation ${var.installer_ip}:/tmp/bundle/post_deployment_scripts/reset-core-installation" : "mv /tmp/reset-core-installation /tmp/bundle/post_deployment_scripts/reset-core-installation",
      // retrive the load balancer private ip and set it as env parameter in installer
      "echo 'Getting the LoadBalancer IP'",
      var.loadbalancer_dns != "" ? "ping -c1 ${var.loadbalancer_dns} | sed -nE 's/^PING[^(]+\\(([^)]+)\\).*/\\1/p' > /tmp/nlb-ip.txt" : "echo 'no load balancer was provided - skip'",
      "echo 'LoadBalancer IP is: `cat /tmp/nlb-ip.txt'",
      // remove all the temp files
      "rm -rf /tmp/reset-core-installation",
      var.loadbalancer_dns != "" ? (var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/nlb-ip.txt ${var.installer_ip}:/tmp/bundle/post_deployment_scripts/nlb-ip.txt" : "mv /tmp/nlb-ip.txt /tmp/bundle/post_deployment_scripts/nlb-ip.txt") : "echo 'no load balancer was provided - skip'",
      var.loadbalancer_dns != "" ? (var.installer_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.installer_ip} 'sudo -H -u ${var.generated_username} bash -c \"echo 'export LB_IP=`cat /tmp/nlb-ip.txt`' >> ~${var.generated_username}/.bash_profile'\"" : "sudo -H -u ${var.generated_username} bash -c \"echo 'export LB_IP=`cat /tmp/bundle/post_deployment_scripts/nlb-ip.txt`' >> ~${var.generated_username}/.bash_profile\"") :  "echo 'no load balancer was provided - skip'"
    ]
  }
}