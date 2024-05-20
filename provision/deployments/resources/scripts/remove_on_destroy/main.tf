variable "files_to_remove" {
  type = list(string)
  description = "the files array to remove on destroy"
}
resource "null_resource" "remove_on_destroy" {
  triggers = {
    files_to_remove = join(" ",var.files_to_remove)
  }
  provisioner "local-exec" {
    command = "rm -rf  ${self.triggers.files_to_remove}"
    when    = destroy
  }
}