# Terraform Infrastructure

This directory contains modular Terraform for BookVault infrastructure.

## Layout

- `bootstrap/`: creates backend resources (S3 state bucket + DynamoDB lock table)
- `modules/vpc/`: VPC, subnets, route tables, IGW, NAT gateways
- `modules/ecr/`: ECR repository (`bookvault-api`)
- `modules/alb/`: Application Load Balancer, listener, target group (`/health` check)
- `modules/ecs/`: ECS cluster, Fargate service, task definition
- `modules/secrets_manager/`: optional managed application secrets
- `modules/route53/`: optional DNS alias record to the ALB
- `environments/dev/`: development stack composition
- `environments/prod/`: production stack composition

## 1) Bootstrap backend

From `terraform/bootstrap`:

```bash
terraform init
terraform apply
```

Capture outputs:
- `state_bucket_name`
- `lock_table_name`

## 2) Deploy an environment

From `terraform/environments/dev` (or `prod`):

```bash
terraform init \
  -backend-config="bucket=<state_bucket_name>" \
  -backend-config="dynamodb_table=<lock_table_name>"

terraform plan -out tfplan
terraform apply tfplan
```

## Notes

- Default API container port is `8000`
- ALB target group health check path is `/health`
- ECS service runs in private subnets behind the ALB
- Image reference is built from ECR URL + `container_image_tag`
