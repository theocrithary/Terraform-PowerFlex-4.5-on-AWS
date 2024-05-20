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
variable "csv_basic_location" {
  type = string
  description = "the path to the csv basic file location"
}
variable "reset_core_location" {
  type = string
  description = "the path to the reset core directory location"
}
variable "post_deployment_location" {
  type = string
  description = "the path to the post deployment script location"
}
variable "convert_csv_location" {
  type = string
  description = "the path to the convert csv script location"
}
variable "atlantic_override_location" {
  type = string
  description = "the path to the atlantic override files"
}
variable "deployment_mode" {
  type = string
  description = "decide whatever this deployment is in single/multi az"
  default = "single"
}
variable "pfmp_override_location" {
  type = string
  description = "the path to the pfmp override files"
}
variable "installer_ip" {
  type = string
  description = "the installer private ip"
}
variable "co_res_ips" {
  type = list(string)
  description = "the list of co-res private ips"
}
variable "pfmp_bundle_version" {
  type = string
  description = "the location and the version of the pfmp bundle on the server"
}
variable "loadbalancer_dns" {
  type = string
  description = "the load balancer dns domain name"
}
resource "null_resource" "copy-installation-scripts" {
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

  provisioner "file" {
    source      = var.csv_basic_location
    destination = "/tmp/CSV_basic.csv"
  }

  provisioner "file" {
    source      = var.reset_core_location
    destination = "/tmp/reset-core-installation"
  }

  provisioner "file" {
    source      = var.post_deployment_location
    destination = "/tmp/post_deployment.sh"
  }

  provisioner "file" {
    source      = var.convert_csv_location
    destination = "/tmp/convert_csv_to_ips.sh"
  }

  provisioner "file" {
    source      = var.atlantic_override_location
    destination = "/tmp/atlantic_override"
  }

  provisioner "file" {
    source      = var.pfmp_override_location
    destination = "/tmp/pfmp_override"
  }

  provisioner "remote-exec" {
    inline = [
      // convert files to linux encoding
      "dos2unix /tmp/post_deployment.sh /tmp/reset-core-installation/* /tmp/CSV_basic.csv /tmp/run_pfmp_deployment.sh /tmp/convert_csv_to_ips.sh /tmp/atlantic_override/* /tmp/pfmp_override/*",
      // create the post deployment directory in the mno servers
      "ssh -o 'StrictHostKeyChecking no' ${var.co_res_ips[0]} 'mkdir -p /tmp/bundle/post_deployment_scripts'",
      "ssh -o 'StrictHostKeyChecking no' ${var.co_res_ips[1]} 'mkdir -p /tmp/bundle/post_deployment_scripts'",
      "ssh -o 'StrictHostKeyChecking no' ${var.co_res_ips[2]} 'mkdir -p /tmp/bundle/post_deployment_scripts'",
      // create the post deployment directory in the installer
      var.installer_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.installer_ip} 'mkdir -p /tmp/bundle/post_deployment_scripts'" : "mkdir -p /tmp/bundle/post_deployment_scripts",
      // update the core deployment csv with the servers ip's
      "chmod +x /tmp/convert_csv_to_ips.sh /tmp/reset-core-installation/*",
      "/tmp/convert_csv_to_ips.sh ${join(" ",var.co_res_ips)}",
      // update the reset core scripts with the servers ip's
      "cd /tmp/reset-core-installation && ./build-clean-core-mno.sh ${join(" ",var.co_res_ips)}",
      // change permissions of core deployment csv and run pfmp script
      "chmod 644 /tmp/core_deployment.csv && chmod +x /tmp/run_pfmp_deployment.sh",
      // update the installer server with all the relevant scripts
      var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/run_pfmp_deployment.sh ${var.installer_ip}:/tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh" : "mv /tmp/run_pfmp_deployment.sh /tmp/bundle/${var.pfmp_bundle_version}/run_pfmp_deployment.sh",
      var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' -r /tmp/reset-core-installation ${var.installer_ip}:/tmp/bundle/post_deployment_scripts/reset-core-installation" : "mv /tmp/reset-core-installation /tmp/bundle/post_deployment_scripts/reset-core-installation",
      var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/core_deployment.csv ${var.installer_ip}:/tmp/bundle/core_deployment.csv" : "mv /tmp/core_deployment.csv /tmp/bundle/core_deployment.csv",
      var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/post_deployment.sh ${var.installer_ip}:/tmp/bundle/post_deployment_scripts/post_deployment.sh" : "mv /tmp/post_deployment.sh /tmp/bundle/post_deployment_scripts/post_deployment.sh",
      // in case of multi az deployment - need to modify atlantic deployment script to support CrossSubnet ip mode
      var.deployment_mode == "multi" ? (var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/pfmp_override/default_vars_t.json ${var.installer_ip}:/tmp/bundle/${var.pfmp_bundle_version}/PFMP_Installer/templates/default_vars_t.json" : "mv /tmp/pfmp_override/default_vars_t.json /tmp/bundle/${var.pfmp_bundle_version}/PFMP_Installer/templates/default_vars_t.json") : "echo 'no need - skipping'",
      var.deployment_mode == "multi" ? (var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/pfmp_override/keycloakrealm_t.json ${var.installer_ip}:/tmp/bundle/${var.pfmp_bundle_version}/PFMP_Installer/templates/keycloakrealm_t.json" : "mv /tmp/pfmp_override/keycloakrealm_t.json /tmp/bundle/${var.pfmp_bundle_version}/PFMP_Installer/templates/keycloakrealm_t.json") : "echo 'no need - skipping'",
      var.deployment_mode == "multi" ? (var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' -r /tmp/atlantic_override ${var.installer_ip}:/tmp/bundle/atlantic_override" : "mv /tmp/atlantic_override /tmp/bundle/atlantic_override") : "echo 'no need - skipping'",
      // retrive the load balancer private ip and set it as env parameter in installer
      "echo 'Getting the LoadBalancer IP'",
      "ping -c1 ${var.loadbalancer_dns} | sed -nE 's/^PING[^(]+\\(([^)]+)\\).*/\\1/p' > /tmp/nlb-ip.txt",
      "echo 'LoadBalancer IP is: `cat /tmp/nlb-ip.txt'",
      var.installer_ip != "" ? "scp -o 'StrictHostKeyChecking no' /tmp/nlb-ip.txt ${var.installer_ip}:/tmp/bundle/post_deployment_scripts/nlb-ip.txt" : "mv /tmp/nlb-ip.txt /tmp/bundle/post_deployment_scripts/nlb-ip.txt",
      var.installer_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.installer_ip} 'echo 'export LB_IP=`cat /tmp/nlb-ip.txt`' >> /home/ec2-user/.bash_profile'" : "echo 'export LB_IP=`cat /tmp/bundle/post_deployment_scripts/nlb-ip.txt`' >> /home/ec2-user/.bash_profile",
      // remove all the temp files
      "rm -rf /tmp/CSV_basic.csv /tmp/temp*.csv /tmp/core_deployment.csv /tmp/reset-core-installation /tmp/post_deployment.sh /tmp/install_core.sh /tmp/run_pfmp_deployment.sh /tmp/atlantic_override /tmp/pfmp_override"
    ]
  }
}