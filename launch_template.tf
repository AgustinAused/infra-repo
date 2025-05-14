data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Crear Instance Profile asociado al LabRole
resource "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
  role = data.aws_iam_role.lab_role.name
}

resource "aws_launch_template" "backend" {
  name_prefix   = "backend-lt-"
  image_id      = var.backend_ami_id
  instance_type = var.ec2_type
  key_name      = var.key_pair_name
  iam_instance_profile {
    name = aws_iam_instance_profile.lab_profile.name  # Asignar el Instance Profile
  }
  user_data = base64encode(file("${path.module}/user-data.sh"))

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "backend-instance"
    }
  }
  depends_on = [aws_security_group.ec2_sg]
}