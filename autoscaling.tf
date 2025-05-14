# ---------------------------------------------------
# Launch Template - Config de instancias backend
# ---------------------------------------------------
resource "aws_autoscaling_group" "backend_asg" {
  name                      = "backend-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "backend-instance"
    propagate_at_launch = true
  }

  force_delete = true
  depends_on = [
    aws_lb_target_group.backend,
    aws_security_group.ec2_sg
  ]
}
# --------------------------------------------------
# ASG Backend - Instancias con escalado automático
# --------------------------------------------------
resource "aws_autoscaling_attachment" "backend" {
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
  lb_target_group_arn    = aws_lb_target_group.backend.arn
}