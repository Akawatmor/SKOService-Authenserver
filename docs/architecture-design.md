# System Architecture & Design Specification
## Project: SAuthenServer

### 1. Overview
SAuthenServer is a centralized Authentication and Authorization service designed to secure various internal and external services. It acts as a single source of truth for user identity and access control (RBAC).

### 2. Technology Stack
- **Framework:** Next.js (App Router)
  - Serves both the Frontend User Interface (Login, Profile, Management) and the Backend API (OIDC/OAuth endpoints, Management APIs).
- **Language:** TypeScript
- **Database:** PostgreSQL
- **Authentication Library:** Auth.js (formerly NextAuth.js)
  - Handles session management, OAuth handshakes, and strict security protocols.
- **ORM (Suggested):** Prisma (for type-safe database interactions)
- **Deployment:** Containerized (Docker) running on Proxmox LXC.

### 3. Architecture Diagrams

#### 3.1 High-Level Context
```mermaid
graph LR
    User[User / Client] -->|HTTPS| LoadBalancer
    LoadBalancer --> SAuthenServer[SAuthenServer (Next.js)]
    SAuthenServer -->|Read/Write| DB[(PostgreSQL)]
    SAuthenServer -->|OAuth| Google[Google Identity]
    SAuthenServer -->|OAuth| Github[GitHub]
    SAuthenServer -->|OAuth| Cloudflare[Cloudflare Access]
    
    ServiceA[Client Service A] -->|Validate Token| SAuthenServer
    ServiceB[Client Service B] -->|Validate Token| SAuthenServer
```

#### 3.2 Authentication Flow (SSO)
1. User visits `Client Service A`.
2. `Client Service A` redirects User to `SAuthenServer`.
3. `SAuthenServer` presents Login Page (Google, GitHub, Creds).
4. User authenticates.
5. `SAuthenServer` creates a session and redirects back to `Client Service A` with an artifact (Callback).
6. `Client Service A` exchanges artifact for User User/Tokens.

### 4. Key Components

#### 4.1 Core Authentication (Auth.js)
- **Providers:**
  - `CredentialsProvider`: For username/password login (legacy support).
  - `GoogleProvider`: OIDC.
  - `GitHubProvider`: OAuth.
  - `CloudflareProvider`: Custom OIDC/OAuth.
- **Session Strategy:** Database-backed sessions (for ability to revoke sessions remotely).

#### 4.2 User Management Module
- User Profile management.
- Admin dashboard for RBAC (Role-Based Access Control).

#### 4.3 API Layer (Next.js API Routes)
- `/api/auth/*`: Handled by Auth.js.
- `/api/v1/users`: User management.
- `/api/v1/introspect`: For other services to validate tokens (if not using stateless JWTs).

### 5. Integration with Proxmox (Infrastructure)
The application will be built as a Docker container or a Node.js standalone artifact.
- **Runtime:** Node.js > 20 (LTS)
- **Environment:** Linux Container (LXC)
- **Reverse Proxy:** Nginx (recommended inside or in front of LXC) to handle SSL offloading before hitting Next.js.
