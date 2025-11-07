module "ec2" {
  source                      = "./modules/ec2"
  name                        = "sujal-openvpn-ec2"
  ami_id                      = "ami-0caa91d6b7bee0ed0"
  vpc_id                      =  "vpc-00096c429250a0988"
  subnet_id                   = "subnet-0117aad7564e0686e"
  instance_type               = "t2.micro"
  key_name                    = "sujal-openvpn-key"
  associate_public_ip_address = true
  user_data = file("user_data.sh")
  sg_ingress =  [
    { from_port = 1194, to_port = 1194, protocol = "udp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]}
  ]
}





