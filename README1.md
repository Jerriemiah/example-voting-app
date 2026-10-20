# Example Voting App

A containerized voting application composed of a Python vote service, a .NET worker, a Node.js result service, PostgreSQL, and Redis.

## Project Status

### Completed: Step 2 — Container Hardening

The following hardening tasks have been completed:

- Base images are pinned by digest.
- Application containers run as non-root users.
- `.dockerignore` files are present for the relevant build contexts.
- All application images build successfully.
- All application services start successfully.
- The production-oriented Compose configuration is the default `docker-compose.yml`.
- The development configuration is preserved as `docker-compose.development.yml`.

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
- A web browser.
- `curl`, recommended for endpoint verification.

Verify the installation:

```bash
docker --version
docker compose version
git --version
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

The development configuration may include:

- Source-code bind mounts.
- Development servers.
- `nodemon`.
- Debugging configuration.
- Development-oriented commands.

Stop the development stack with:

```bash
docker compose -f docker-compose.development.yml down
```

## Build and Run

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

The ignored content may include:

- Git metadata.
- Local dependency directories.
- Python cache files.
- Node.js dependency directories.
- Test artifacts.
- Logs.
- Local environment files.

This reduces build context size and prevents local-only files from being copied into images.

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

The expected result is:

```text
example-voting-app-vote    Built
example-voting-app-worker  Built
example-voting-app-result  Built
```

If Docker reports a transient BuildKit cache or snapshot-export error, retry the affected service individually. If necessary, clear unused builder cache:

```bash
docker builder prune -af
```

Then rebuild the services one at a time.

## Verification

### Service Health

```bash
docker compose ps
```

Confirm that PostgreSQL and Redis report healthy status and that the application services are running.

### HTTP Endpoints

```bash
curl -s -o /dev/null -w 'vote HTTP %{http_code}\n' \
  http://localhost:8080/

curl -s -o /dev/null -w 'result HTTP %{http_code}\n' \
  http://localhost:8081/
```

Expected output:

```text
vote HTTP 200
result HTTP 200
```

### Runtime Identity

```bash
docker compose exec vote id
docker compose exec result id
docker compose exec worker id
```

Expected users:

```text
vote   → app, UID 10001
result → node, UID 1000
worker → app, UID 10001
```

### Service Integration Logs

```bash
docker compose logs --tail=50 worker
docker compose logs --tail=50 result
```

Expected worker indicators include:

```text
Connected to db
Connecting to redis
Found redis at <container-IP>
Processing vote for '<choice>' by '<voter-id>'
```

Expected result indicator:

```text
Connected to db
```

### End-to-End Workflow

1. Open the vote application at `http://localhost:8080`.
2. Cast votes for the available choices.
3. Open the result application at `http://localhost:8081`.
4. Confirm that the result totals update.
5. Inspect the worker and result logs.

The expected flow is:

```text
Vote submission
→ Redis queue
→ .NET worker
→ PostgreSQL
→ Result page
```

## Verification Record

The following Step 2 checks have been completed:

| Check | Status |
|---|---|
| Base images pinned by digest | Complete |
| `.dockerignore` files added | Complete |
| Vote image builds | Complete |
| Worker image builds | Complete |
| Result image builds | Complete |
| Vote service starts | Complete |
| Worker service starts | Complete |
| Result service starts | Complete |
| Vote runs as non-root | Complete |
| Worker runs as non-root | Complete |
| Result runs as non-root | Complete |
| PostgreSQL starts healthy | Complete |
| Redis starts healthy | Complete |
| Vote-to-result workflow verified | Complete |

## Development Commands

Start the development configuration:

```bash
docker compose -f docker-compose.development.yml up -d --build
```

View development logs:

```bash
docker compose -f docker-compose.development.yml logs -f
```

Stop the development stack:

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

Use `docker compose down -v` only when you intentionally want to delete the database volume.

## Next Step

Step 2 established reproducible, non-root, production-style container images with reduced build contexts.

The next phase can focus on the deployment configuration, including:

- Kubernetes manifests or Helm charts.
- Container port standardization.
- Kubernetes `securityContext`.
- Deployments and Services.
- Readiness and liveness probes.
- Secrets and configuration.
- Persistent storage.
- Local Kubernetes validation.
- EKS deployment preparation.
