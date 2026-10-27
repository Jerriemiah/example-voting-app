# Example Voting App

A containerized voting application composed of a Python Vote service, a .NET Worker, a Node.js Result service, PostgreSQL, and Redis.

The project demonstrates a complete DevOps workflow:

```text
Application code
→ GitHub Actions validation and image builds
→ SHA-tagged images in GitHub Container Registry
→ Terraform-provisioned Amazon EKS
→ Helm deployment
→ Deliberate failure
→ Helm rollback
```

![Architecture](architecture.excalidraw.png)

## Project Status

### Completed: Step 2 — Container Hardening

- Base images are pinned by digest.
- Application containers run as non-root users.
- `.dockerignore` files are present for the relevant build contexts.
- All application images build successfully.
- All application services start successfully.
- The production-oriented Compose configuration is the default `docker-compose.yml`.
- The development configuration is preserved as `docker-compose.development.yml`.

### Completed: Capstone 1 — Terraform, EKS, CI/CD, Helm, and Rollback

- Terraform provisions the AWS VPC, subnets, EKS cluster, managed node group, and required security-group rules.
- GitHub Actions validates the application, runs integration tests, builds images, scans them with Trivy, and publishes SHA-tagged images to GHCR.
- A single Helm chart deploys Vote, Result, Worker, Redis, and PostgreSQL to EKS.
- The application was deployed successfully and verified end to end.
- A deliberately faulty image upgrade was performed and recovered using a Helm rollback.
- Terraform state and plan files remain local and are excluded from Git.

## Architecture

| Service | Technology | Responsibility | Runtime user |
|---|---|---|---|
| Vote | Python | Accepts votes through the web interface | `app`, UID 10001 |
| Worker | .NET | Transfers votes from Redis to PostgreSQL | `app`, UID 10001 |
| Result | Node.js | Displays voting results | `node`, UID 1000 |
| Redis | Redis | Queues incoming votes | Redis image user |
| DB | PostgreSQL | Stores processed votes and totals | PostgreSQL image user |

### Application Flow

```text
User
 │
 ▼
Vote service
 │
 ▼
Redis
 │
 ▼
Worker
 │
 ▼
PostgreSQL
 │
 ▼
Result service
```

## Repository Structure

```text
.
├── vote/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── ...
├── worker/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── ...
├── result/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── ...
├── seed-data/
│   ├── Dockerfile
│   └── ...
├── healthchecks/
├── voting-app/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── infrastructure/
│   └── terraform/
│       ├── *.tf
│       └── terraform.tfvars.example
├── .github/workflows/
├── docker-compose.yml
├── docker-compose.development.yml
├── docker-compose.images.yml
└── README.md
```

## Prerequisites

Install the following tools before running the project:

- Docker Engine or Docker Desktop.
- Docker Compose v2.
- Git.
- Terraform.
- AWS CLI.
- `kubectl`.
- Helm.
- A web browser.
- `curl`, recommended for endpoint verification.

Verify the installation:

```bash
docker --version
docker compose version
git --version
terraform version
aws --version
kubectl version --client
helm version
```

## Configuration Files

### Production Compose

The default `docker-compose.yml` is intended for production-style local verification.

It:

- Builds the application images from their final Dockerfile stages.
- Runs the application containers as non-root users.
- Does not depend on application-source bind mounts.
- Uses digest-pinned Redis and PostgreSQL images.
- Exposes the vote and result web interfaces locally.

Start it with:

```bash
docker compose up -d --build
```

### Development Compose

The development configuration is preserved separately:

```bash
docker compose -f docker-compose.development.yml up -d --build
```

The development configuration may include source-code bind mounts, development servers, `nodemon`, debugging configuration, and development-oriented commands.

Stop the development stack with:

```bash
docker compose -f docker-compose.development.yml down
```

## Build and Run Locally

Start the production-style stack:

```bash
docker compose up -d --build
```

Check the service status:

```bash
docker compose ps
```

Expected services include:

```text
db       Up (healthy)
redis    Up (healthy)
vote     Up
worker   Up
result   Up
```

Open the application:

```text
Vote:   http://localhost:8080
Result: http://localhost:8081
```

Stop the stack:

```bash
docker compose down
```

To remove the database volume as well:

```bash
docker compose down -v
```

> Warning: Removing volumes deletes the persisted PostgreSQL data and resets the voting data.

## Container Hardening

### Digest-Pinned Base Images

The Dockerfiles and Compose infrastructure image references use SHA-256 digests instead of relying only on mutable tags.

Examples:

```dockerfile
FROM python:3.11-slim-trixie@sha256:<digest>
```

```dockerfile
FROM node:18-bookworm-slim@sha256:<digest>
```

```dockerfile
FROM mcr.microsoft.com/dotnet/runtime:7.0@sha256:<digest>
```

The digest ensures that the exact referenced image content is used during the build.

To review image references:

```bash
grep -RInE '^[[:space:]]*FROM |image:' \
  --include='Dockerfile' \
  --include='compose*.yml' \
  --include='docker-compose*.yml' \
  .
```

### Non-Root Runtime Users

The application services run with non-root identities:

```text
vote:   uid=10001(app) gid=10001(app)
result: uid=1000(node) gid=1000(node)
worker: uid=10001(app) gid=10001(app)
```

Verify the runtime users:

```bash
docker compose exec vote id
docker compose exec result id
docker compose exec worker id
```

Expected output:

```text
uid=10001(app) gid=10001(app) groups=10001(app)
uid=1000(node) gid=1000(node) groups=1000(node)
uid=10001(app) gid=10001(app) groups=10001(app)
```

### `.dockerignore`

Each application build context includes a `.dockerignore` file to prevent unnecessary files from being sent to the Docker daemon.

The ignored content may include Git metadata, local dependency directories, Python cache files, Node.js dependency directories, test artifacts, logs, and local environment files.

Review the files with:

```bash
find . -name .dockerignore -print
```

## Image Builds

Build the individual production images:

```bash
docker compose build --no-cache vote
docker compose build --no-cache worker
docker compose build --no-cache result
```

Build all services:

```bash
docker compose build --no-cache
```

Expected result:

```text
example-voting-app-vote    Built
example-voting-app-worker  Built
example-voting-app-result  Built
```

## CI/CD Pipeline

The GitHub Actions workflow performs the following stages:

1. Lint and validate the application code.
2. Run integration tests.
3. Build Vote, Worker, and Result images.
4. Scan the built images with Trivy.
5. Tag images with the immutable Git commit SHA.
6. Push the images to GitHub Container Registry (GHCR).

The EKS deployment consumes SHA-tagged images from GHCR, ensuring that a deployment refers to the exact image produced by a specific commit.

## Terraform and Amazon EKS

The Terraform configuration under `infrastructure/terraform/` provisions:

- A VPC and private subnets across multiple Availability Zones.
- An Amazon EKS cluster.
- A managed node group.
- Required security-group rules.
- Supporting AWS networking resources.

Initialize and validate Terraform:

```bash
cd infrastructure/terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Create the infrastructure:

```bash
terraform apply
```

Destroy the infrastructure when no longer needed:

```bash
terraform destroy
```

> Warning: `terraform destroy` deletes the AWS resources created by this configuration.

### Terraform Safety

Do not commit Terraform state, plan files, `.terraform/` directories, or real variable files. These files may contain infrastructure metadata and potentially sensitive values.

The repository ignores:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
```

Use `terraform.tfvars.example` as the documented template for required local values.

## Helm Deployment

The voting application is packaged as one Helm chart in [`voting-app`](./voting-app). The chart deploys Vote, Result, Worker, Redis, PostgreSQL, and their required Kubernetes Services.

| Component | Kubernetes resources | Access |
|---|---|---|
| PostgreSQL | `voting-app-db` Deployment + `db` Service | `ClusterIP`, port 5432 |
| Redis | `voting-app-redis` Deployment + `redis` Service | `ClusterIP`, port 6379 |
| Worker | `voting-app-worker` Deployment | No Service; background consumer |
| Vote | `voting-app-vote` Deployment + `vote` Service | `NodePort` |
| Result | `voting-app-result` Deployment + `result` Service | `NodePort` |

Helm values define environment-specific settings, including:

- GHCR image repositories and immutable Git commit-SHA tags.
- Replica counts.
- Service types and ports.
- PostgreSQL credentials and application connection settings.
- Resource names, labels, and selectors.

Validate the chart before deployment:

```bash
helm lint voting-app
helm template voting-app ./voting-app --namespace <NAMESPACE>
```

Install or upgrade the release:

```bash
helm upgrade --install voting-app ./voting-app \
  --namespace <NAMESPACE> \
  --create-namespace \
  --values voting-app/values.yaml
```

Verify the release and workloads:

```bash
helm list --namespace <NAMESPACE>
helm history voting-app --namespace <NAMESPACE>
kubectl get pods -n <NAMESPACE>
kubectl get services -n <NAMESPACE>
kubectl get endpoints vote result -n <NAMESPACE>
```

## EKS Verification

After deployment, confirm that all application Pods are running:

```bash
kubectl get pods -n <NAMESPACE>
```

Expected result:

```text
voting-app-db       1/1     Running
voting-app-redis    1/1     Running
voting-app-result   1/1     Running
voting-app-vote     1/1     Running
voting-app-worker   1/1     Running
```

Check that Vote and Result Services route only to their own Pods:

```bash
kubectl get endpoints vote result -n <NAMESPACE>
```

Vote and Result should each expose a distinct backend Pod IP.

Test the Vote endpoint from inside the cluster:

```bash
kubectl run curl-vote --rm -it \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  -- curl -I http://vote:8080
```

Submit a test vote:

```bash
kubectl run curl-vote-post --rm -it \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  -- curl -i -X POST -d "vote=a" http://vote:8080/
```

Confirm that the Worker processed the vote:

```bash
kubectl logs deployment/voting-app-worker -n <NAMESPACE> --tail=20
```

Expected evidence includes:

```text
Connected to db
Found redis at <redis-service-ip>
Processing vote for 'a' by '<voter-id>'
```

## Rollback Demonstration

A deliberately faulty image upgrade was deployed to create a failed release. The Result image tag was changed to a nonexistent value, causing the replacement Result Pod to enter `ImagePullBackOff`.

The application was restored with Helm by rolling back to revision 1:

```bash
helm rollback voting-app 1 --namespace <NAMESPACE>
```

Rollback evidence:

```text
REVISION  UPDATED                  STATUS      CHART              APP VERSION  DESCRIPTION
1         <timestamp>              superseded  voting-app-0.1.0   1.16.0       Install complete
2         <timestamp>              superseded  voting-app-0.1.0   1.16.0       Upgrade complete
3         <timestamp>              deployed    voting-app-0.1.0   1.16.0       Rollback to 1
```

The Helm history output is the primary rollback evidence because it explicitly records that revision 3 restored the application to revision 1. The recovered Result Pod returned to a healthy state and used the known-good SHA-tagged image.

## Verification Record

| Check | Status |
|---|---|
| Base images pinned by digest | Complete |
| `.dockerignore` files added | Complete |
| Vote image builds | Complete |
| Worker image builds | Complete |
| Result image builds | Complete |
| Application containers run as non-root | Complete |
| PostgreSQL and Redis start healthy locally | Complete |
| Vote-to-result workflow verified locally | Complete |
| Terraform provisions EKS infrastructure | Complete |
| GitHub Actions builds and publishes SHA-tagged GHCR images | Complete |
| Helm chart deploys all five application components | Complete |
| Vote and Result Services route to the correct Pods | Complete |
| End-to-end vote flow verified on EKS | Complete |
| Faulty upgrade observed and rolled back successfully | Complete |

## Development Commands

Start the development configuration:

```bash
docker compose -f docker-compose.development.yml up -d --build
```

View development logs:

```bash
docker compose -f docker-compose.development.yml logs -f
```

Stop the development configuration:

```bash
docker compose -f docker-compose.development.yml down
```

Start the production-style configuration:

```bash
docker compose up -d --build
```

View production-style logs:

```bash
docker compose logs -f
```

## Troubleshooting

### Check all containers

```bash
docker compose ps
```

### View service logs

```bash
docker compose logs vote
docker compose logs worker
docker compose logs result
docker compose logs db
docker compose logs redis
```

### Check runtime users

```bash
docker compose exec vote id
docker compose exec worker id
docker compose exec result id
```

### Rebuild from scratch

```bash
docker compose down
docker builder prune -af
docker compose build --no-cache
docker compose up -d --force-recreate
```

### Investigate a failing Kubernetes Pod

For an `ImagePullBackOff` or another Pod failure, inspect its events and logs:

```bash
kubectl describe pod <POD_NAME> -n <NAMESPACE>
kubectl logs <POD_NAME> -n <NAMESPACE>
```

The `Events` section usually identifies an invalid image reference, registry permissions issue, network problem, or scheduling issue.

## Next Steps

Potential production improvements include:

- Kubernetes `securityContext` settings for all workloads.
- Readiness and liveness probes.
- Kubernetes Secrets for database credentials.
- Persistent volumes for PostgreSQL.
- Ingress with TLS instead of NodePort access.
- Horizontal Pod Autoscaling.
- Automated Helm deployment from GitHub Actions.
- Automated rollback on failed deployment health checks.