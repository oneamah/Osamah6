# Marmil Blog App

This workspace provisions a private AWS-backed blog application behind an HTTPS ALB at `https://marmil.co`.

## Overview

The application is a small blog platform with:

- a public multi-page website
- an admin editor at `/admin`
- PostgreSQL-backed posts and comments
- Redis connectivity for runtime dependency validation
- S3-backed image uploads for post cover images
- infrastructure managed with Terraform and HCP Terraform

The current deployment publishes:

- `GET /` as the public home page
- `GET /posts/{slug}` as dedicated article pages
- `GET /admin` as the editor and media upload interface

## Architecture

- Route 53 record and ACM certificate for `marmil.co`
- public Application Load Balancer with HTTPS
- private Auto Scaling Group running the Python blog app
- private RDS PostgreSQL instance
- private ElastiCache Redis replication group
- public S3 media bucket for uploaded images
- AWS Secrets Manager for database credentials, app source, admin credentials, and Redis auth token
- CloudWatch Logs for instance application logs
- SSM and related VPC endpoints for private instance management without public SSH

## Tools Used

Infrastructure and workflow tools used in this repo:

- Terraform for infrastructure as code
- HCP Terraform for remote state, runs, and apply workflow
- Dockerized Terraform CLI for local `validate`, `plan`, and `apply` execution
- VS Code Terraform MCP configuration in [.vscode/mcp.json](.vscode/mcp.json)

AWS services used by the deployed system:

- Amazon VPC
- Application Load Balancer
- Auto Scaling Group
- Amazon EC2
- Amazon RDS for PostgreSQL
- Amazon ElastiCache for Redis
- Amazon S3
- AWS Secrets Manager
- Amazon Route 53
- AWS Certificate Manager
- Amazon CloudWatch Logs
- AWS Systems Manager and VPC endpoints

## Repository Layout

- [main.tf](main.tf): Terraform version, cloud block, and provider requirements
- [vpc.tf](vpc.tf): VPC, subnets, and networking base
- [ec2.tf](ec2.tf): ALB, Auto Scaling Group, bootstrap wiring, and runtime environment
- [rds.tf](rds.tf): PostgreSQL database configuration
- [cache.tf](cache.tf): Redis replication group configuration
- [storage.tf](storage.tf): S3 media bucket and public object access for uploaded images
- [auth.tf](auth.tf): generated admin credentials secret
- [app_source.tf](app_source.tf): blog application source delivered through Secrets Manager
- [templates/blog-app.py.tftpl](templates/blog-app.py.tftpl): Python backend and HTML rendering logic
- [templates/backend-bootstrap.sh.tftpl](templates/backend-bootstrap.sh.tftpl): EC2 startup bootstrap script

## Website Routes

- `GET /` home page with published post cards
- `GET /posts/{slug}` public post detail page
- `GET /admin` admin login and editor page

## Admin Credentials

Admin credentials are stored in AWS Secrets Manager.

- Secret output: `blog_admin_secret_arn`
- Secret JSON fields:
  - `username`
  - `password`
  - `token_secret`

Example retrieval:

```powershell
aws secretsmanager get-secret-value --secret-id <blog_admin_secret_arn> --query SecretString --output text
```

## Common Commands

Validate Terraform:

```powershell
docker run --rm -v "${PWD}:/workspace" -w /workspace hashicorp/terraform:1.14 validate
```

Plan with HCP Terraform credentials:

```powershell
docker run --rm -e TF_TOKEN_app_terraform_io="$env:TF_TOKEN_app_terraform_io" -v "${PWD}:/workspace" -w /workspace hashicorp/terraform:1.14 plan -no-color
```

Apply with HCP Terraform credentials:

```powershell
docker run --rm -e TF_TOKEN_app_terraform_io="$env:TF_TOKEN_app_terraform_io" -v "${PWD}:/workspace" -w /workspace hashicorp/terraform:1.14 apply --auto-approve
```

## API Contract

Public endpoints:

- `GET /`
- `GET /admin`
- `GET /posts/{slug}`
- `GET /ready`
- `GET /health`
- `GET /api/posts`
- `GET /api/posts/{id}`
- `GET /api/posts/{id}/comments`
- `POST /api/posts/{id}/comments`

Authenticated admin endpoints:

- `POST /api/auth/login`
- `GET /api/auth/me`
- `POST /api/uploads`
- `POST /api/posts`
- `PUT /api/posts/{id}`
- `DELETE /api/posts/{id}`
- `DELETE /api/comments/{id}`

## Media Uploads

- Uploaded post images are stored in the public S3 bucket exposed by the `media_bucket_name` output.
- Uploaded image URLs are returned under the `media_base_url` output and can be saved as a post cover image.
- The admin page uploads image bytes to `POST /api/uploads`, and the backend stores them under the S3 `posts/` prefix.

## Auth Header

After `POST /api/auth/login`, send the returned bearer token in:

```text
Authorization: Bearer <token>
```

## Core Entities

- `posts`: title, slug, summary, content, cover image URL, tags, published state, timestamps
- `comments`: post reference, author name, author email, content, timestamp

## Notes

- The blog backend source is stored in Secrets Manager as a compressed payload to stay under the service size limit.
- A launch template change triggers instance replacement so application updates roll out through the Auto Scaling Group.
# Osamah6
