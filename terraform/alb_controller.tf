resource "aws_iam_role" "alb_controller" {
  name               = "lab-commit-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
}

resource "aws_iam_policy" "alb_controller" {
  name   = "lab-commit-AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.aws_load_balancer_controller_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

