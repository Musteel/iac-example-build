variable "location" {
    description = "Azure region where the resources will be deployed"
    default     = "westeurope"
}

variable "admin_username" {
    description = "Username for the admin user"
    default     = "azureuser"
}

variable "ssh_key_path" {
    description = "Path to the SSH key file"
    default     = "~/.ssh/id_rsa.pub"
}