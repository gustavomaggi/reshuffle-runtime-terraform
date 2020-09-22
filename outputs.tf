output "database-credentials" {
  value = "${0 < var.dbInstanceCount ?
    "${aws_db_instance.primary[0].username}:${aws_db_instance.primary[0].password}" :
    "n/a"
  }"
}
output "url" {
  value = "${var.zoneid == "" ?
    "Please configure a DNS alias from ${var.system}.${var.domain} to ${aws_lb.lb.dns_name}" :
    "Your runtime is accessible at https://${var.system}.${var.domain}/"
  }"
}
