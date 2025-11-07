resource "aws_instance" "instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  source_dest_check           = var.source_dest_check
  user_data                   = var.user_data

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}