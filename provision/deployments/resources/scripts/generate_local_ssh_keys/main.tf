variable "keys_path" {
  type = string
  description = "the location of the generated keys to be save in"
}
variable "timestamp" {
  type = string
  description = "the current timestamp"
}

resource "null_resource" "generate-local-ssh-keys" {
  provisioner "local-exec" {
    command = "ssh-keygen -t rsa -b 4096 -m PEM -q -N '' -f ${var.keys_path}/powerflex-denver-key-${var.timestamp} && cp ${var.keys_path}/powerflex-denver-key-${var.timestamp} ${var.keys_path}/powerflex-denver-key "
  }
}

output "output_files" {
  description = "The output files"
  value       = ["${var.keys_path}/powerflex-denver-key-${var.timestamp}","${var.keys_path}/powerflex-denver-key-${var.timestamp}.pub"]
}