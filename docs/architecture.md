# BookVault Architecture

![BookVault architecture](assets/bookvault_architecture.png)

## Overview

BookVault is a containerized Book Catalog API deployed on AWS using a production-style cloud architecture.

The service is designed to demonstrate practical DevOps and platform engineering concepts including:

- Infrastructure as Code
- Containerized application deployment
- High availability across multiple Availability Zones
- Secure secret handling
- Centralized logging
- CI/CD automation
- Outbound integration with a third-party API

The API acts as a lightweight service layer in front of the Google Books API. Users send requests to BookVault, and BookVault retrieves and returns book data in a simplified format.

---

## Architecture Goals

This architecture was designed with the following goals in mind:

1. **Keep the application secure**
   - The application containers run in private subnets
   - Only the load balancer is publicly accessible

2. **Follow a AWS deployment pattern**
   - DNS with Route 53
   - Traffic entry through an Application Load Balancer
   - Containers running on ECS Fargate
   - Image storage in ECR
   - Logs in CloudWatch
   - Secrets in AWS Secrets Manager

3. **Support high availability**
   - Workloads are distributed across two Availability Zones
   - The design avoids placing all compute in a single failure domain

4. **Separate responsibilities clearly**
   - Route 53 handles DNS
   - ALB handles incoming traffic distribution
   - ECS manages container lifecycle
   - Fargate runs the application tasks
   - NAT Gateways provide outbound internet access for private workloads

5. **Demonstrate DevOps practices**
   - GitHub Actions builds and deploys the application
   - ECR stores the container image
   - AWS services handle runtime concerns such as logging and secrets

---

## High-Level Architecture

At a high level, the BookVault system looks like this:

- Users access the service through the internet
- Route 53 resolves the application domain
- An Application Load Balancer receives incoming requests
- The ALB forwards requests to ECS tasks running in private subnets
- Each ECS task runs the BookVault container on AWS Fargate
- The container retrieves configuration from Secrets Manager
- The container sends logs to CloudWatch
- The container calls the Google Books API through a NAT Gateway
- GitHub Actions builds and deploys new versions of the application

---

## Main Components

### Users

Users represent clients consuming the BookVault API. These could be:

- A browser
- Postman
- `curl`
- Another backend service

Users never connect directly to the application containers. All traffic enters through the public-facing load balancer.

---

### Route 53 DNS Resolver

Route 53 is used for DNS resolution.

Its role in this architecture is to map a friendly domain name such as `api.bookvault.example.com` to the public endpoint of the Application Load Balancer.

This allows the application to be accessed through a stable and professional domain name rather than a raw AWS-generated endpoint.

**Why we chose Route 53**
- Native AWS DNS service
- Standard choice for production AWS architectures
- Integrates cleanly with load balancers and other AWS services

---

### AWS Region and VPC

The application is deployed inside a single AWS region and a dedicated VPC.

The VPC provides an isolated private network for all infrastructure components. In this project, the VPC uses a CIDR range of `10.0.0.0/16`.

This gives enough address space to separate the environment into multiple subnets across multiple Availability Zones.

**Why we chose a dedicated VPC**
- Isolates the application network from other AWS resources
- Allows fine-grained subnet, routing, and security design

---

### Internet Gateway

The Internet Gateway is attached to the VPC and enables internet connectivity for resources that need public access, either directly or indirectly through routing.

In this architecture, the Internet Gateway supports:
- Public-facing network paths
- Outbound internet connectivity from public subnets
- NAT Gateway access to the internet

**Why it exists:**
Without an Internet Gateway, the VPC would not be able to exchange traffic with the internet.

---

### Availability Zones

The architecture is split across **Availability Zone A** and **Availability Zone B**.

Each Availability Zone contains:
- One public subnet
- One private subnet

This improves resilience. If one Availability Zone experiences a problem, the service can continue running in the other zone.

**Why we chose multi-AZ deployment**
- Increases availability
- Reduces single points of failure

---

### Public Subnets

Each Availability Zone contains a public subnet.

Public subnets are used for components that require internet connectivity at the network level. In this project, they contain:
- The Application Load Balancer
- NAT Gateways

**Why we use public subnets**
- Public subnets can route traffic to the Internet Gateway
- NAT Gateways must live in public subnets
- The ALB must be reachable from the internet

---

### Private Subnets

Each Availability Zone also contains a private subnet.

Private subnets host the application runtime:
- ECS Fargate tasks
- BookVault containers

Private subnets do **not** allow direct inbound internet access to the containers.

**Why we run application tasks in private subnets**
- Reduces attack surface
- Prevents direct internet access to containers
- Forces traffic through controlled entry points such as the ALB

---

### Application Load Balancer

The Application Load Balancer is the public entry point for BookVault.

Its job is to:
- Receive incoming HTTP/HTTPS requests
- Route requests to healthy application tasks
- Distribute traffic across multiple application instances

**Why we chose an ALB**
- Standard AWS choice for HTTP/HTTPS services
- Supports routing to ECS workloads
- Distributes traffic across multiple tasks and Availability Zones
- Improves reliability and scalability

---

### Elastic Container Service (ECS)

Amazon ECS is the container orchestration layer in this architecture.

Its job is to:
- Manage the BookVault service definition
- Determine how many tasks should run
- Restart failed tasks
- Coordinate deployment of new application versions
- Distribute tasks across subnets and Availability Zones

ECS is a logical management layer. It does not replace the load balancer and it does not directly serve requests to users.

**Why we chose ECS**
- Simpler to adopt than Kubernetes for this project
- Production-capable AWS-native container orchestration
- Integrates well with Fargate, CloudWatch, ECR, and load balancers

---

### AWS Fargate

Fargate is the compute engine used by ECS to run containers.

Instead of managing EC2 instances manually, Fargate allows containers to run without provisioning or maintaining servers.

In this project:
- Each Fargate task runs the BookVault API container
- Tasks are distributed across private subnets in two Availability Zones

**Why we chose Fargate**
- Removes the need to manage worker nodes or virtual machines
- Simpler operational model
- Emphasizes container operations rather than server maintenance

---

### BookVault Container

The BookVault container is the actual application.

Its responsibilities include:
- Receiving requests forwarded by the load balancer
- Processing BookVault API endpoints
- Retrieving configuration or secrets
- Calling the Google Books API
- Returning a simplified response to the client
- Emitting logs for debugging and observability

This is the business logic layer of the system.

---

### Amazon ECR

Amazon Elastic Container Registry stores the Docker image for the BookVault application.

GitHub Actions builds the application image and pushes it to ECR. ECS then pulls the image from ECR during deployment.

**Why we chose ECR**
- AWS-native container registry
- Simple integration with ECS
- Secure and standard choice for container image storage in AWS environments

---

### AWS Secrets Manager

Secrets Manager stores sensitive application configuration such as:
- API keys
- Tokens
- Environment-specific secrets
- Credentials or secret values needed by the application

The BookVault container retrieves secrets at runtime rather than embedding them directly in source code or container images.

**Why we chose Secrets Manager**
- Avoids hardcoding sensitive values
- Supports secure runtime secret retrieval
- Demonstrates a stronger security practice than using plain environment variables alone

---

### Amazon CloudWatch

CloudWatch is used for logging and observability.

The application sends logs to CloudWatch so developers can:
- Inspect runtime behavior
- Troubleshoot issues
- Verify successful deployments
- Monitor application activity

**Why we chose CloudWatch**
- Native AWS logging service
- Integrates easily with ECS
- Centralizes logs from distributed containers

---

### Google Books API

Google Books is an external third-party dependency.

The BookVault container calls the Google Books API to fetch book data, then returns a simplified or transformed response to the user.

This allows the project to focus on infrastructure and operational design rather than building a large custom data store from scratch.

**Why we chose Google Books**
- Relevant to the project theme
- Vast database
- Free to use

---

## 1. Request Flow

The main user request flow is:

1. A user sends a request to the BookVault API over the internet
2. Route 53 resolves the requested domain name
3. The request reaches the Application Load Balancer
4. The ALB forwards the request to the BookVault service running on ECS
5. ECS routes traffic to a healthy Fargate task in one of the private subnets
6. The BookVault container processes the request
7. If book data is needed, the container makes an outbound call to the Google Books API
8. The response is returned from the container through the ALB back to the user

This flow ensures:
- Clients only talk to the public entry point
- Containers remain private
- Requests can be distributed across multiple running tasks

---

## 2. Deployment Flow

The CI/CD flow in this architecture is:

1. The developer writes or updates code locally
2. Code is pushed to GitHub
3. GitHub Actions runs the deployment pipeline
4. The pipeline builds the BookVault container image
5. The image is pushed to Amazon ECR
6. ECS is updated to use the new image version
7. New Fargate tasks are launched with the updated container

This creates a clean separation between:
- Source control
- Build automation
- Image storage
- Runtime deployment

---

## 3. Logging Flow

The logging flow is simple but important:

1. The BookVault application emits logs during startup and request processing
2. ECS/Fargate sends those logs to CloudWatch
3. Developers can inspect logs in CloudWatch for debugging and operational visibility

This provides centralized observability for a distributed application.

---

## 4. Secrets and Configuration Flow

The application uses AWS Secrets Manager for sensitive runtime data.

Typical flow:
1. The BookVault container starts
2. It retrieves required secrets from Secrets Manager
3. It uses those values to configure outbound API calls or environment-specific behavior

**Why this matters**
- Prevents secrets from being committed to Git
- Avoids baking secrets into Docker images
- Reflects secure application deployment practices

---

## Why These Design Choices Were Made

### Why ECS instead of Kubernetes?

Kubernetes is powerful, but it would add significant complexity to a project whose main goal is to demonstrate practical DevOps fundamentals.

We chose ECS because:
- It is simpler to set up and explain
- it integrates naturally with other AWS services
- it keeps focus on cloud architecture, automation, and deployment

### Why Fargate instead of EC2?

Using Fargate removes the need to manage:
- Instance provisioning
- OS patching
- Worker scaling
- Cluster node maintenance

This lets the project focus on containerized application delivery rather than infrastructure patching.

---

## Security Considerations

This architecture includes several good security practices:

- **Private application runtime:** Containers run in private subnets

- **Controlled public entry point:** Users access the service only through the ALB

- **Secret management:** Sensitive values are stored in Secrets Manager

- **Isolated networking:** Infrastructure is deployed inside a dedicated VPC

Additional improvements that could be added later:
- Security groups documentation
- HTTPS termination with ACM
- WAF in front of the ALB
- IAM least-privilege policies for ECS tasks
- Secret rotation policies

---

## Scalability and Reliability

The current design already supports a reasonable degree of scalability and reliability.

### Reliability
- Workloads are split across two Availability Zones
- ECS can restart failed tasks
- ALB can route traffic to healthy tasks

### Scalability
- Multiple tasks can run simultaneously
- The ALB can distribute traffic across tasks
- ECS service scaling can be added later

Possible future improvements:
- ECS service auto scaling
- Health-check tuning
- Blue/Green deployments
- Caching layer for external API responses

---

## Future Improvements

Possible next improvements for BookVault include:

- ECS auto scaling policies
- HTTPS with ACM certificates
- Blue/Green deployments
- Application metrics and dashboards
- AWS WAF
- Rate limiting
- Redis or in-memory caching
- Health check tuning
- Terraform module decomposition
- Prometheus/Grafana or OpenTelemetry integration

---

## Summary

BookVault uses a modern AWS container deployment pattern built around Route 53, an Application Load Balancer, ECS Fargate, ECR, Secrets Manager, CloudWatch, and private subnets distributed across two Availability Zones. The architecture was intentionally chosen to be secure, operationally clean and easy to explain
