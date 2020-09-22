resource "random_string" "dbUser" {
  length  = 16
  special = false
}

resource "random_string" "dbPassword" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "default" {
  count      = 0 < var.dbInstanceCount ? 1 : 0
  name       = "reshuffle-${var.system}-dbsng"
  subnet_ids = aws_subnet.subnet.*.id
  tags       = local.defaultTags
}

resource "aws_db_instance" "primary" {
  count                     = 0 < var.dbInstanceCount ? 1 : 0

  # Specific to primary
  name                       = var.system
  identifier                 = "reshuffle-${var.system}-db"
  tags                       = local.defaultTags
  username                   = random_string.dbUser.result
  password                   = random_string.dbPassword.result
  backup_retention_period    = var.dbBackupRetentionDays
  db_subnet_group_name       = aws_db_subnet_group.default[0].name

  # Shared with replicas.  Copy changes to "readonly_replicas" below.
  allocated_storage          = var.dbAllocatedGB
  apply_immediately          = true
  auto_minor_version_upgrade = true
  engine                     = "postgres"
  engine_version             = "12.3"
  instance_class             = var.dbInstanceClass
  max_allocated_storage      = var.dbAllocatedMaxGB
  publicly_accessible        = false
  skip_final_snapshot        = true
  storage_encrypted          = true
  vpc_security_group_ids     = [aws_security_group.sgdb[0].id]
}

resource "aws_db_instance" "replica" {
  count                      = max(0, var.dbInstanceCount - 1)

  # Specific to secondary
  name                       = var.system
  identifier                 = "reshuffle-${var.system}-db-replica-${count.index}"
  tags                       = local.defaultTags
  replicate_source_db        = aws_db_instance.primary[0].id

  # Shared with replicas.  Copy changes from "primary" above.
  allocated_storage          = var.dbAllocatedGB
  apply_immediately          = true
  auto_minor_version_upgrade = true
  engine                     = "postgres"
  engine_version             = "12.3"
  instance_class             = var.dbInstanceClass
  max_allocated_storage      = var.dbAllocatedMaxGB
  publicly_accessible        = false
  skip_final_snapshot        = true
  storage_encrypted          = true
  vpc_security_group_ids     = [aws_security_group.sgdb[0].id]
}
