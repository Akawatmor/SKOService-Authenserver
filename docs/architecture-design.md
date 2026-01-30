# System Architecture & Design Specification
## Project: SAuthenServer

### 1. Overview
SAuthenServer is a centralized Authentication and Authorization service designed to secure various internal and external services. It acts as a single source of truth for user identity and access control (RBAC).

### 2. Technology Stack

#### Frontend
- **Framework:** Next.js 15 (App Router)
  - Serves the User Interface (Login, Profile, Management Dashboard)
  - Communicates with backend via RESTful API
- **Runtime:** Bun - High-performance JavaScript runtime
- **Language:** TypeScript
- **UI Library:** React 18
- **Styling:** Tailwind CSS + Shadcn/ui components
- **State Management:** Zustand
- **API Client:** Axios + TanStack Query (React Query)

#### Backend
- **Language:** Go (Golang) 1.22+
- **Framework:** Fiber v2
  - High-performance web framework built on Fasthttp
  - Express-like API design
- **Database:** PostgreSQL 16
- **Database Toolkit:** sqlc
  - Generates type-safe Go code from SQL queries
  - Eliminates ORM overhead
- **Cache:** Redis 7
  - Session storage
  - Rate limiting
  - OAuth state management
- **Authentication:**
  - PASETO (Platform-Agnostic Security Tokens)
  - OAuth2 (Google, GitHub, Cloudflare)
  - Bcrypt for password hashing
- **API Documentation:** Swagger/OpenAPI 3.0

#### Infrastructure
- **Containerization:** Docker + Docker Compose
- **Reverse Proxy:** Traefik v2
  - Automatic HTTPS with Let's Encrypt
  - Load balancing
  - Rate limiting
  - Security headers
- **Deployment:** Docker Swarm / Kubernetes / Proxmox LXC

### 3. Architecture Diagrams

#### 3.1 High-Level Architecture
```mermaid
graph TB
    Client[User Browser] -->|HTTPS| Traefik[Traefik Reverse Proxy]
    
    Traefik -->|Route /| Frontend[Next.js Frontend<br/>Port 3000]
    Traefik -->|Route /api| Backend[Go Fiber Backend<br/>Port 8080]
    
    Backend -->|SQL Queries| PostgreSQL[(PostgreSQL<br/>Database)]
    Backend -->|Cache/Sessions| Redis[(Redis Cache)]
    Backend -->|OAuth| Google[Google OAuth]
    Backend -->|OAuth| GitHub[GitHub OAuth]
    Backend -->|OAuth| Cloudflare[Cloudflare Access]
    
    Frontend -->|API Calls| Backe with PASETO)
```mermaid
sequenceDiagram
    participant User
    participant ClientApp as Client Service
    participant Frontend as Next.js UI
    participant Backend as Go API
    participant DB as PostgreSQL
    participant Redis
    participant OAuth as OAuth Provider

    User->>ClientApp: Access protected resource
    ClientApp->>Frontend: Redirect to login
    Frontend->>User: Display login options
    
    alt OAuth Login (Google/GitHub)
        User->>Frontend: Click OAuth provider
        Frontend->>Backend: Request OAuth URL
        Backend->>OAuth: Initiate OAuth flow
        OAuth-->>User: Redirect to provider
        User->>OAuth: Authenticate
        OAuth->>Backend: Callback with code
        BBackend API (Go + Fiber)
**Core Modules:**
- **Authentication Service**
  - PASETO token generation and validation
  - OAuth2 integration (Google, GitHub, Cloudflare)
  - Password hashing with bcrypt
  - Session management via Redis
  
- **User Management Service**
  - CRUD operations for users
  - Profile management
  - Email verification
  
- **RBAC Service**
  - Role and permission management
  - Dynamic permission checking
  - User role assignment
  Deployment Architecture

#### 5.1 Docker Compose (Development & Small Production)
All services run as containers:
- Traefik (ports 80, 443, 8081 dashboard)
- Backend (internal port 8080)
- Frontend (internal port 3000)
- PostgreSQL (port 5432)
- Redis (port 6379)

**Benefits:**
- Easy local development
- Consistent environments
- Simplified deployment on single servers
- Perfect for Proxmox LXC deployment

#### 5.2 Production Deployment Options

**Option A: Proxmox LXC with Docker**
1. Create Ubuntu/Debian LXC container
2. Install Docker and Docker Compose
3. Clone repository
4. Run `docker-compose up -d`
5. Configure Traefik for SSL certificates
6. Point domain DNS to LXC IP

**Option B: Kubernetes**
- Helm charts for easy deployment
- Horizontal pod autoscaling
- Rolling updates with zero downtime
- Health checks and self-healing

**Option C: Cloud Platforms**
- AWS: ECS + RDS + ElastiCache
- Azure: Container Apps + PostgreSQL + Redis Cache
- GCP: Cloud Run + Cloud SQL + Memorystore

#### 5.3 High Availability Setup
```mermaid
graph TB
    LB[Load Balancer]
    
    LB --> T1[Traefik 1]
    LB --> T2[Traefik 2]
    
    T1 --> BE1[Backend 1]
    T1 --> BE2[Backend 2]
    T1 --> BE3[Backend 3]
    
    T2 --> BE1
    T2 --> BE2
    T2 --> BE3
    
    BE1 --> PG[(PostgreSQL<br/>Primary)]
    BE2 --> PG
    BE3 --> PG
    
    PG -.Replication.-> PG_R[(PostgreSQL<br/>Replica)]
    
    BE1 --> RC[Redis Cluster]
    BE2 --> RC
    BE3 --> RC
```

### 6. Security Considerations

#### 6.1 Authentication Security
- **PASETO v4** (public key cryptography)
- Bcrypt password hashing (cost factor 12)
- Secure session storage in Redis with TTL
- CSRF protection on state-changing operations
- Rate limiting on login endpoints

#### 6.2 Network Security
- HTTPS enforced via Traefik
- Security headers (CSP, HSTS, X-Frame-Options)
- CORS properly configured
- SQL injection prevention via parameterized queries (sqlc)

#### 6.3 Data Security
- Sensitive data encrypted at rest
- No passwords in logs
- Regular database backups
- PII handling compliance (GDPR ready)

### 7. Performance Optimizations

#### 7.1 Backend
- Connection pooling (pgx)
- Redis caching for frequently accessed data
- Compiled queries with sqlc (no ORM overhead)
- Fiber's zero-allocation router
- gzip compression on API responses

#### 7.2 Frontend
- Next.js incremental static regeneration
- Image optimization
- Code splitting
- Bun's fast bundling and runtime
- CDN for static assets

#### 7.3 Database
- Proper indexing strategy
- Query optimization
- Connection pooling
- Prepared statements via sqlc

### 8. Monitoring & Observability

#### 8.1 Logging
- Structured JSON logging
- Log aggregation with ELK stack
- Audit trail for security events

#### 8.2 Metrics
- Traefik metrics endpoint
- Custom application metrics
- Redis performance metrics
- PostgreSQL slow query log

#### 8.3 Tracing
- OpenTelemetry support
- Distributed tracing across services
- Request ID propagation

### 9. Development Workflow

#### 9.1 Local Development
```bash
# Install dependencies
cd frontend && bun install
cd ../backend && go mod download

# Generate sqlc code
make sqlc

# Start services
docker-compose up -d postgres redis
cd backend && go run cmd/server/main.go
cd frontend && bun dev
```

#### 9.2 Testing Strategy
- **Backend:** Go unit tests + integration tests
- **Frontend:** Jest + React Testing Library
- **E2E:** Playwright for critical flows
- **Load Testing:** k6 for performance benchmarks

#### 9.3 CI/CD Pipeline
1. Lint (golangci-lint, ESLint)
2. Unit tests
3. Build Docker images
4. Integration tests
5. Security scan (Trivy)
6. Push to registry
7. Deploy to staging
8. Smoke tests
9. Deploy to production

**API Endpoints:**
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - Credentials login
- `POST /api/v1/auth/logout` - Session termination
- `GET /api/v1/auth/oauth/:provider` - OAuth initiation
- `GET /api/v1/auth/oauth/:provider/callback` - OAuth callback
- `POST /api/v1/auth/refresh` - Refresh PASETO token
- `GET /api/v1/auth/validate` - Token validation for external services
- `GET /api/v1/users` - List users (admin)
- `GET /api/v1/users/:id` - Get user details
- `PUT /api/v1/users/:id` - Update user
- `GET /api/v1/roles` - List roles
- `POST /api/v1/roles/:id/users/:userId` - Assign role

#### 4.2 Frontend (Next.js + Bun)
**Pages:**
- `/` - Landing page
- `/login` - Login page with OAuth buttons
- `/register` - Registration form
- `/profile` - User profile management
- `/admin/users` - User management dashboard
- `/admin/roles` - Role management
- `/admin/logs` - Audit logs viewer

**Features:**
- Server-side rendering for SEO
- Client-side state management with Zustand
- Optimistic UI updates
- Real-time session validation
- Responsive design with Tailwind CSS

#### 4.3 Database Layer (PostgreSQL + sqlc)
**Advantages of sqlc:**
- Compile-time SQL validation
- Type-safe database queries
- Zero runtime overhead (no reflection)
- Better performance than traditional ORMs
- PostgreSQL-specific optimizations

**Schema:**
- Uses PostgreSQL schema `authenserver_service`
- Fully normalized tables
- Optimized indexes for common queries
- Foreign key constraints for data integrity

#### 4.4 Caching Layer (Redis)
**Use Cases:**
- Session storage (key: `session:{token}`)
- OAuth state management
- Rate limiting counters
- Recently accessed user data
- Permission cache (TTL: 5 minutes)
    Backend->>Redis: Check session
    Backend-->>ClientApp: User info + permissions
    ClientApp->>User: Grant access
```
    style PostgreSQL fill:#336791
    style Redis fill:#dc382d
    style Traefik fill:#24a1c1
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
