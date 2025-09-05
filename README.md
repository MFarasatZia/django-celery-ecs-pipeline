# Django + Celery CI/CD Pipeline (Bitbucket ➜ AWS ECS/ECR)

> 🚀 A full-featured CI/CD pipeline template that automates testing, quality checks, secure DB migration validation, container builds, and AWS ECS/ECR deployment with Slack notifications.

---

## 📌 About This Project  

This repository demonstrates a **production-grade Bitbucket pipeline** that I designed and implemented to handle the entire lifecycle of a Django + Celery application.  

It reflects my **DevOps skillset across testing, automation, containerization, and cloud deployment**.  

**Pipeline capabilities include:**  
- ✅ Conditional PR validation  
- ✅ Automated unit testing with coverage enforcement  
- ✅ SonarCloud code quality gates  
- ✅ Auto-handling of migrations post-merge  
- ✅ Secure DB migration validation using **restored RDS snapshots**  
- ✅ Docker build & tagging strategy (app + celery worker)  
- ✅ AWS ECR push & ECS service updates  
- ✅ Slack notifications (success/failure with duration tracking)  
- ✅ Rollback strategy for safe recovery  

---

## ⚙️ Tech Stack  

- **CI/CD**: Bitbucket Pipelines (self-hosted runners)  
- **Runtime**: Django + Celery  
- **Containers**: Docker, Docker Compose, Poetry  
- **Databases**: PostgreSQL, Redis, AWS RDS  
- **Deployment**: AWS ECS (Fargate), AWS ECR  
- **Storage**: AWS S3 (static/media)  
- **Quality Gate**: SonarCloud  
- **Notifications**: Slack Webhooks  

---

## 🔄 CI/CD Workflow  

### 1. Pull Requests (to `dev`, `staging`, `main`)  
- Run **unit tests** with `coverage --fail-under=95`  
- Generate `coverage.xml`  
- Perform **SonarQube scan** with PR decoration  

### 2. Branch: `dev`  
- **Step 1 – Auto Merge Migrations**  
  - Wait for Postgres readiness  
  - Install dependencies with Poetry  
  - Run `makemigrations --merge`  
  - Auto-commit and push new migration files back to `dev`  

- **Step 2 – Build + Test + Deploy**  
  - Capture pipeline start time  
  - Register Slack error handler (sends alerts on failure)  
  - Build Docker images for:  
    - `web` service (Django + Gunicorn + Nginx)  
    - `celery` worker  
  - Apply tagging strategy:  
    - `latest`  
    - `YYYY-MM-DD-<shortSHA>` (immutable build tags)  

  - **Migration Test (RDS Snapshot Strategy):**  
    - Restore latest **staging RDS snapshot** into a temporary DB  
    - Run migrations on this test DB  
    - If failure → rollback and delete test DB immediately  
    - If success → delete DB and continue  
    - ✅ This ensures migrations are **tested safely before touching real environments**  

  - Push images to **AWS ECR**  
  - Register new **ECS task definitions** (web + celery)  
  - Update ECS services to deploy new tasks  
  - Send **Slack success message** with build duration + link  

### 3. (Optional) Rollback Job  
- Restore ECS service to a previous Docker image tag  
- Validate rollback images exist  
- Update ECS task definitions back  
- Notify Slack on success  

---

## 📊 CI/CD Flow Diagram  

```mermaid
flowchart TD
  A[Pull Request] --> B[Run Unit Tests + Coverage ≥95%]
  B --> C[SonarCloud Scan]
  C -->|Merge to dev| D[Auto Merge Migrations]
  D --> E[Restore RDS Snapshot for Migration Test]
  E -->|Fail| F[Slack: Migration Failed + Rollback DB]
  E -->|Pass| G[Build Docker Images (Web + Celery)]
  G --> H[Push Images to AWS ECR]
  H --> I[Update ECS Task Definitions]
  I --> J[Deploy to ECS Services]
  J --> K[Slack: Pipeline Passed]

```
## 🗂️ Repository Structure  

.
├── Dockerfile                   # Web app (Django + Nginx + Gunicorn)
├── Dockerfile.Celery             # Celery worker image
├── docker-compose.docker.yml     # Local dev stack (Postgres, Redis, App)
├── docker-compose.bitbucket.yml  # CI-only Postgres service
├── entrypoint.sh                 # Web startup (migrations, collectstatic, gunicorn)
├── entrypoint-celery.sh          # Celery worker startup
├── nginx.conf                    # Nginx reverse proxy config
├── gunicorn.conf.py              # Gunicorn WSGI config
├── bitbucket-pipelines.yml       # Full CI/CD pipeline definition
├── sonar-project.properties      # SonarCloud config
├── .env.example                  # Safe sample env vars
├── scripts/
│   ├── create-new-task-def.sh
│   ├── create-new-task-def-celery.sh
│   └── report-build-result.sh
└── README.md
