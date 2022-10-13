provider "http" {

}

variable "hello_world" {
  type    = string
  default = "hello, world!"
}

output "hello_world_out" {
  value = var.hello_world
}
