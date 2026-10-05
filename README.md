# TaskFlow API — Full-Stack CI/CD Pipeline

A task management REST API (Node.js/Express) deployed to AWS ECS Fargate via
a fully automated CI/CD pipeline, with Prometheus/Grafana monitoring and
Slack alerting. Built as an end-to-end DevOps learning project — every piece
of infrastructure is defined in Terraform, every deploy goes through GitHub
Actions.

## Architecture

```
GitHub push → GitHub Actions (lint, unit tests, integration tests)
                    │
                    ▼
            terraform apply (OIDC, no stored AWS keys)
                    │
                    ▼
            Build & push image → ECR → ecs update-service
                    │
                    ▼
Client → ALB (path-based routing)
           ├─→ "/"         → TaskFlow API   (ECS Fargate, private subnet)
           └─→ "/grafana*" → Grafana        (ECS Fargate, private subnet)
                                  │
                                  ▼ (Cloud Map DNS: prometheus.taskflow.local)
                               Prometheus   (ECS Fargate, private subnet)
                                  │
                                  ▼ (scrapes taskflow-api.taskflow.local:3000/metrics)
                               TaskFlow API
```

All three services sit in private subnets behind a NAT Gateway. Only the ALB
is internet-facing. Services find each other via **AWS Cloud Map** private
DNS (`taskflow.local`), not hardcoded IPs — Fargate tasks don't have stable
addresses, so DNS-based discovery is what makes this reliable.

## Stack

| Layer | Tech |
|---|---|
| App | Node.js, Express |
| Containers | Docker (multi-stage builds) |
| Registry | Amazon ECR |
| Orchestration | Amazon ECS (Fargate) |
| Networking | VPC, public/private subnets (2 AZs), ALB, NAT Gateway, Cloud Map |
| IaC | Terraform, S3 + DynamoDB remote state backend |
| CI/CD | GitHub Actions, OIDC (no long-lived AWS credentials) |
| Monitoring | Prometheus (`prom-client` metrics) |
| Dashboards | Grafana |
| Alerting | Grafana unified alerting → Slack |

## Local development

```bash
npm install
cp .env.example .env
npm run dev
```

Runs on `http://localhost:3000`. Key endpoints:

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Liveness check |
| GET | `/metrics` | Prometheus metrics (default Node.js metrics + `http_requests_total`) |
| GET/POST/PUT/DELETE | `/api/tasks` | Task CRUD |

### Tests

```bash
npm test              # unit + integration, with coverage
npm run lint
```

### Docker

```bash
docker build -t taskflow-api .
docker compose up      # runs the API + a Postgres container
```

## Infrastructure (Terraform)

State is stored remotely in S3 with DynamoDB locking, so local and CI runs
share the same state:

- Bucket: `taskflow-terraform-state-221792772427`
- Lock table: `terraform-locks`

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**What gets provisioned:**
- VPC with public/private subnets across 2 AZs, NAT Gateway, Internet Gateway
- Security groups, scoped by reference (ALB → app, app → Prometheus, etc.) rather than open CIDRs
- Application Load Balancer with path-based routing (`/` → API, `/grafana*` → Grafana)
- ECS cluster (`taskflow-cluster`) running three Fargate services: `taskflow` (API), `prometheus`, `grafana`
- ECR repositories: `taskflow-api`, `taskflow-prometheus`
- Cloud Map private DNS namespace (`taskflow.local`) for service discovery
- CloudWatch Log Groups per service
- IAM: `ecs_task_role` (app-level permissions, e.g. ECS Exec via SSM) and `ecs_execution_role` (ECS's own permissions to pull images / write logs)
- GitHub Actions OIDC identity provider + two scoped IAM roles (`github-actions-terraform`, `github-actions-deploy`) — no AWS access keys stored in GitHub

### Remote access (no SSH)

ECS Exec is enabled instead of SSH — no bastion host, no open port 22,
connects over SSM through VPC interface endpoints (`ssm`, `ssmmessages`,
`ec2messages`):

```bash
aws ecs execute-command \
  --cluster taskflow-cluster \
  --task <task-id> \
  --container taskflow-api \
  --interactive --command "/bin/sh"
```

## CI/CD pipeline

GitHub Actions workflow (`ci.yml`):

1. **lint** — ESLint
2. **unit-tests** / **integration-tests** — run in parallel, gate the pipeline
3. **terraform-apply** — plan + apply against the remote S3/DynamoDB backend, authenticated via OIDC (no stored credentials)
4. **deploy** — build the Docker image, push to ECR, `aws ecs update-service --force-new-deployment`

## Monitoring

- **Prometheus** scrapes `/metrics` from the API every 15s via Cloud Map (`taskflow-api.taskflow.local:3000`)
- **Metrics exposed:** default Node.js process metrics (CPU, memory, event loop lag) via `prom-client`, plus a custom `http_requests_total{method, route, status_code}` counter
- **Grafana** is served behind the ALB at `/grafana` (subpath routing configured via `GF_SERVER_ROOT_URL` + `GF_SERVER_SERVE_FROM_SUB_PATH`), with Prometheus added as a data source and dashboard ID `11159` (Node.js/Express) imported as a starting point

## Alerting (Slack)

Configured through Grafana's built-in unified alerting:

1. Create a Slack Incoming Webhook (Slack App → Incoming Webhooks)
2. **Grafana → Alerting → Contact points** → add a Slack contact point with the webhook URL
3. Create alert rules against the Prometheus data source:

| Alert | Query | Condition | Purpose |
|---|---|---|---|
| TaskFlow API Down | `up{job="taskflow-api"}` | below 1 for 2m | Detects the app failing health checks |
| High Error Rate | `sum(rate(http_requests_total{status_code=~"5.."}[5m]))` | above 0 | Flags 5xx errors in the last 5 minutes |

Both route to the `slack-alerts` contact point.

## Teardown

```bash
terraform plan -destroy   # review first
terraform destroy
```

Verify nothing billable is left behind:
```bash
aws elbv2 describe-load-balancers
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
```

ECR repositories are kept by default (image storage is a few cents/month) —
`terraform destroy` won't remove a repo with images in it unless
`force_delete = true` is set. The S3 state bucket and DynamoDB lock table
are also left in place; they cost effectively nothing and let you
`terraform apply` again later without re-running the import steps for
pre-existing resources.

## Lessons learned

A few real issues hit and fixed along the way, worth knowing if you hit them too:

- **Fargate rejects EC2-only task definition fields** — `sourcePath` (bind
  mounts), `placement_constraints`, and `ordered_placement_strategy` all
  fail at `RegisterTaskDefinition` on Fargate; they're EC2 launch-type only.
- **`awsvpc` network mode requires `network_configuration` on the ECS
  service** — without it, `CreateService` fails outright.
- **CloudWatch log groups aren't auto-created by ECS** — define them
  explicitly and `depends_on` them from the task definition, or tasks fail
  at container start trying to create their own log stream.
- **No remote Terraform backend = lost state on ephemeral CI runners** —
  local state in GitHub Actions disappears after the job ends; an S3 +
  DynamoDB backend keeps local and CI runs in sync.
- **Re-running `apply` after manually deleting infra will conflict** on any
  resources you intentionally kept (IAM roles, log groups) — `terraform
  import` them back into state rather than letting Terraform try to
  recreate what already exists.
- **Grafana needs explicit subpath configuration** behind a path-based ALB
  route — without `GF_SERVER_ROOT_URL` and `GF_SERVER_SERVE_FROM_SUB_PATH`,
  internal redirects (e.g. the login page) break out of the `/grafana`
  prefix.