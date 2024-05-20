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
variable "generated_username" {
  type = string
  description = "the username to generate on the servers"
}
variable "pub_key_location" {
  type = string
  description = "the path to the public key to add in authorized_keys"
}
variable "ssh_keys_path" {
  type = string
  description = "the path to the id_rsa key for the installer api"
}
variable "ssh_ip" {
  type = string
  description = "this parameter is used in case of proxy mode and we need to ssh to the instance from proxy"
  default = ""
}
resource "null_resource" "upload-auto-generated-key" {

  connection {
    type        = "ssh"
    host        = var.host_ip
    user        = var.user
    private_key = file(var.key_location)
  }

  provisioner "file" {
    source      = var.key_location
    destination = "/tmp/id_rsa.pem"
  }

  provisioner "file" {
    source      = var.pub_key_location
    destination = "/tmp/id_rsa.pub"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/id_rsa.pem /tmp/id_rsa && sudo chmod 400 /tmp/id_rsa && sudo chown ${var.user} /tmp/id_rsa",
      var.ssh_ip != "" ? "scp -o 'StrictHostKeyChecking no' -i /tmp/id_rsa /tmp/id_rsa.pem ${var.ssh_ip}:/tmp/id_rsa.pem" : "echo 'No need to SCP files in private subnet mode'",
      var.ssh_ip != "" ? "scp -o 'StrictHostKeyChecking no' -i /tmp/id_rsa /tmp/id_rsa.pub ${var.ssh_ip}:/tmp/id_rsa.pub" : "echo 'No need to SCP files in private subnet mode'",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo useradd ${var.generated_username} -m'" : "sudo useradd ${var.generated_username} -m",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'echo \"${var.generated_username}       ALL=(ALL)      NOPASSWD: ALL\" | sudo EDITOR=\"tee -a\" visudo'" : "echo '${var.generated_username}       ALL=(ALL)      NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo mkdir -p ${var.ssh_keys_path}'" : "sudo mkdir -p ${var.ssh_keys_path}",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo chown ${var.generated_username} /tmp/id_rsa.pem && sudo chown ${var.generated_username} /tmp/id_rsa.pem'" :"sudo chmod 400 /tmp/id_rsa.pem && sudo chown ${var.generated_username} /tmp/id_rsa.pem",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo rm -rf ${var.ssh_keys_path}/id_rsa && sudo cp /tmp/id_rsa.pem ${var.ssh_keys_path}/id_rsa'" :"sudo rm -rf ${var.ssh_keys_path}/id_rsa && sudo cp /tmp/id_rsa.pem ${var.ssh_keys_path}/id_rsa",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo -H -u ${var.generated_username} bash -c \"mkdir -p ~${var.generated_username}/.ssh\"'" :"sudo -H -u ${var.generated_username} bash -c \"mkdir -p ~${var.generated_username}/.ssh\"",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo -H -u ${var.generated_username} bash -c \"touch ~${var.generated_username}/.ssh/authorized_keys\"'" :"sudo -H -u ${var.generated_username} bash -c \"touch ~${var.generated_username}/.ssh/authorized_keys\"",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo -H -u ${var.generated_username} bash -c \"cat /tmp/id_rsa.pub >> ~${var.generated_username}/.ssh/authorized_keys\"'" :"sudo -H -u ${var.generated_username} bash -c \"cat /tmp/id_rsa.pub >> ~${var.generated_username}/.ssh/authorized_keys\"",
      var.ssh_ip != "" ? "ssh -o 'StrictHostKeyChecking no' ${var.ssh_ip} -i /tmp/id_rsa 'sudo -H -u ${var.generated_username} bash -c \"mv /tmp/id_rsa.pem ~${var.generated_username}/.ssh/id_rsa\"'" :"sudo -H -u ${var.generated_username} bash -c \"mv /tmp/id_rsa.pem ~${var.generated_username}/.ssh/id_rsa\"",
      "sudo rm -rf /tmp/id_rsa.pub /tmp/id_rsa.pem /tmp/id_rsa"
    ]
  }
}