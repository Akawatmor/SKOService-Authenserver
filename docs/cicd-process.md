# CI/CD & Development Process

## Development Workflow

### 1. Branching Strategy
We use a **Trunk-Based Development** (or lightweight Feature Branch) workflow.
- **main**: Production-ready code. Auto-deploys to Production (or builds Tag).
- **dev** (Optional): Integration, deploys to Staging.
- **feat/feature-name**: Developers work here. PR to `main` (or `dev`).

### 2. Quality Gates (GitHub Actions)
Every Pull Request must pass the following checks before merging:
1.  **Linting**: `npm run lint` (ESLint).
2.  **Type Checking**: `npm run type-check` (TypeScript generic check).
3.  **Unit Tests**: `npm run test` (Jest/Vitest) for utility functions and non-DB logic.

---

## CI/CD Pipelines

### 1. CI Pipeline (On Pull Request)
**Trigger**: Push to any branch or PR open.
**Jobs**:
- Checkout Code.
- Install Dependencies (`npm ci`).
- Run Lint & Type Check.
- Run Unit Tests.

### 2. CD Pipeline (On Push to Main)
**Trigger**: Push to `main`.
**Jobs**:
1.  **Build Docker Image**:
    - Build Next.js standalone output.
    - Package into Docker Image: `ghcr.io/owner/skoservice-authenserver:latest` (and `:sha`).
2.  **Push to Registry**:
    - Push to GitHub Container Registry (GHCR).

---

## Deployment Strategy (Proxmox LXC)

Since the target infrastructure is **Proxmox LXC**, we have two primary deployment methods:

### Method A: Docker inside LXC (Recommended)
This method keeps the application portable and dependencies isolated.
1.  **Proxmox Setup**:
    - Create an LXC container (Ubuntu/Debian).
    - Install Docker & Docker Compose inside the LXC.
    - Add user data/secrets.
2.  **Deploy**:
    - SSH into LXC (or use a runner).
    - `docker pull ghcr.io/owner/skoservice-authenserver:latest`
    - `docker up -d`

### Method B: Native Node.js on LXC
1.  **Base Image**: Standard Node.js LXC template.
2.  **Deploy**:
    - `git pull` or download artifacts.
    - `npm install --omit=dev`
    - `npm run build`
    - `pm2 start npm --name "authen-server" -- start`

*We will proceed with **Method A (Docker)** for the official plan as it aligns with the "GitHub Action -> Build Artifact" workflow best.*

---

## Testing Plan

### 1. Unit Tests (Jest)
- Test individual functions (e.g., password hashing logic, token parsing).
- Mock database calls.

### 2. Integration Tests
- Test API Routes (`/api/v1/*`).
- Use a temporary DB container.

### 3. End-to-End (E2E) Tests (Playwright/Cypress)
- Simulate a real user logging in.
- **Crucial**: Use the "Verification" design to test SSO flows (mock providers).
