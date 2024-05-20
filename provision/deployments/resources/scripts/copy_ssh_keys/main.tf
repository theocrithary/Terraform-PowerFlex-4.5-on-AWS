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
variable "installer_ip" {
  type = string
  description = "the installer private ip"
}
variable "co_res_ips" {
  type = list(string)
  description = "the list of co-res private ips"
}
variable "co_res_key_location" {
  type = string
  description = "the co res key location"
}
variable "installer_key_location" {
  type = string
  description = "the installer key location"
}
variable "create_ssh_script_location" {
  type = string
  description = "the create_ssh script location"
}
resource "null_resource" "copy-ssh-keys-to-proxy" {

  connection {
    type        = "ssh"
    host        = var.host_ip
    user        = var.user
    private_key = file(var.key_location)
  }

  provisioner "file" {
    source      = var.co_res_key_location
    destination = "/tmp/powerflex-denver-co-res"
  }

  provisioner "file" {
    source      = var.installer_key_location
    destination = "/tmp/powerflex-denver-installer"
  }

  provisioner "file" {
    source      = var.create_ssh_script_location
    destination = "/tmp/create_ssh_file.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /tmp/powerflex-denver-co-res",
      "chmod 400 /tmp/powerflex-denver-installer",
      "chmod +x /tmp/create_ssh_file.sh",
      "mkdir -p ~/pems",
      var.installer_ip != "" ?  "sudo yum install -y dos2unix" : "echo 'no need for installing dos2unix'",
      "dos2unix /tmp/powerflex-denver-co-res /tmp/powerflex-denver-installer /tmp/create_ssh_file.sh",
      "chmod +x /tmp/create_ssh_file.sh",
      var.installer_ip != "" ? "/tmp/create_ssh_file.sh ${var.installer_ip} ${join(" ",var.co_res_ips)}" : "/tmp/create_ssh_file.sh ${var.host_ip} ${join(" ",var.co_res_ips)}" ,
      "chmod 400 ~/.ssh/config",
      "sudo mv /tmp/powerflex-denver-installer ~/pems/powerflex-denver-installer",
      "sudo mv /tmp/powerflex-denver-co-res ~/pems/powerflex-denver-co-res",
      var.installer_ip != "" ?  "scp -o 'StrictHostKeyChecking no' ~/.ssh/config ${var.installer_ip}:~/.ssh/config" : "echo 'no need to copy the ssh config file'",
      "rm -rf /tmp/create_ssh_file.sh"
    ]
  }
}