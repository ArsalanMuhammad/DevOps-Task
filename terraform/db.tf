resource "random_password" "db" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "mysql" {
  name       = "${var.project}-dbsubnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = { Name = "${var.project}-dbsubnets" }
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project}-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "appuser"
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.mysql.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  apply_immediately       = true
  tags = { Name = "${var.project}-mysql" }
}
