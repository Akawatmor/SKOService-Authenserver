# Development Setup Guide

## Quick Start (5 minutes)

```bash
# 1. Clone the repository
git clone <repository-url>
cd SKOService-Authenserver

# 2. Install development tools
make install-tools

# 3. Start infrastructure services
docker-compose up -d postgres redis

# 4. Generate sqlc code
make sqlc

# 5. Setup backend
cd backend
cp .env.example .env
# Edit .env with your settings
go mod download

# 6. Setup frontend
cd ../frontend
cp .env.example .env.local
bun install

# 7. Start development servers
# Terminal 1: Backend
cd backend && go run cmd/server/main.go

# Terminal 2: Frontend
cd frontend && bun dev
```

## Access Points

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **API Docs:** http://localhost:8080/swagger/index.html
- **Traefik Dashboard:** http://localhost:8081 (when using full docker-compose)

## Installation Prerequisites

### Required Tools

1. **Bun** (v1.0+)
   ```bash
   curl -fsSL https://bun.sh/install | bash
   ```

2. **Go** (v1.22+)
   ```bash
   # macOS
   brew install go
   
   # Linux
   wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   ```

3. **Docker & Docker Compose**
   ```bash
   # macOS
   brew install --cask docker
   
   # Linux
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER
   ```

4. **PostgreSQL Client** (optional, for database management)
   ```bash
   # macOS
   brew install postgresql
   
   # Linux
   sudo apt install postgresql-client
   ```

### Development Tools

Install with `make install-tools` or manually:

```bash
# sqlc - SQL to Go code generator
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

# swag - Swagger documentation generator
go install github.com/swaggo/swag/cmd/swag@latest

# migrate - Database migration tool
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# golangci-lint - Go linter
brew install golangci-lint  # macOS
# or
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

## Environment Configuration

### Backend Environment Variables

Create `backend/.env`:

```bash
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/skoservice?sslmode=disable
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=skoservice
DB_SCHEMA=authenserver_service

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# Server
PORT=8080
ENVIRONMENT=development
CORS_ORIGINS=http://localhost:3000

# Authentication
# Generate: openssl rand -base64 32
PASETO_SECRET_KEY=your-32-byte-secret-key-here-replace-this
SESSION_DURATION=24h
REFRESH_TOKEN_DURATION=168h

# OAuth - Google
OAUTH_GOOGLE_CLIENT_ID=your-google-client-id
OAUTH_GOOGLE_CLIENT_SECRET=your-google-client-secret
OAUTH_GOOGLE_REDIRECT_URL=http://localhost:8080/api/v1/auth/oauth/google/callback

# OAuth - GitHub
OAUTH_GITHUB_CLIENT_ID=your-github-client-id
OAUTH_GITHUB_CLIENT_SECRET=your-github-client-secret
OAUTH_GITHUB_REDIRECT_URL=http://localhost:8080/api/v1/auth/oauth/github/callback

# Rate Limiting
RATE_LIMIT_MAX=100
RATE_LIMIT_DURATION=1m
```

### Frontend Environment Variables

Create `frontend/.env.local`:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8080/api
NEXT_PUBLIC_OAUTH_GOOGLE_ENABLED=true
NEXT_PUBLIC_OAUTH_GITHUB_ENABLED=true
```

### OAuth Provider Setup

#### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google+ API
4. Go to Credentials → Create OAuth 2.0 Client ID
5. Application type: Web application
6. Authorized redirect URIs:
   - `http://localhost:8080/api/v1/auth/oauth/google/callback`
   - `https://your-domain.com/api/v1/auth/oauth/google/callback`
7. Copy Client ID and Client Secret to `.env`

#### GitHub OAuth

1. Go to GitHub → Settings → Developer settings → OAuth Apps
2. Click "New OAuth App"
3. Application name: SAuthenServer Development
4. Homepage URL: `http://localhost:3000`
5. Authorization callback URL: `http://localhost:8080/api/v1/auth/oauth/github/callback`
6. Copy Client ID and Client Secret to `.env`

## Database Setup

### Option 1: Docker (Recommended)

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
docker-compose logs -f postgres
# Look for "database system is ready to accept connections"

# Apply schema
docker-compose exec postgres psql -U postgres -d skoservice -f /docker-entrypoint-initdb.d/001_init.sql
```

### Option 2: Local PostgreSQL

```bash
# Create database
createdb skoservice

# Apply schema
psql -d skoservice -f backend/db/schema/001_init.sql

# Verify
psql -d skoservice -c "\dt authenserver_service.*"
```

### Database Migrations

```bash
# Create a new migration
make migrate-create
# Enter migration name when prompted

# Apply migrations
make migrate-up

# Rollback migrations
make migrate-down
```

## Development Workflow

### Backend Development

```bash
cd backend

# Run with hot reload (install air first)
go install github.com/cosmtrek/air@latest
air

# Or run normally
go run cmd/server/main.go

# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Lint code
golangci-lint run

# Generate sqlc code (after modifying SQL files)
make sqlc

# Generate Swagger docs (after adding annotations)
make swagger
```

### Frontend Development

```bash
cd frontend

# Development server with hot reload
bun dev

# Type checking
bun run tsc --noEmit

# Linting
bun lint

# Build for production
bun run build

# Run production build locally
bun start
```

### Full Stack Development

Use multiple terminals:

**Terminal 1 - Infrastructure:**
```bash
docker-compose up postgres redis
```

**Terminal 2 - Backend:**
```bash
cd backend && air  # or go run cmd/server/main.go
```

**Terminal 3 - Frontend:**
```bash
cd frontend && bun dev
```

**Terminal 4 - Testing/Commands:**
```bash
# Run tests, migrations, etc.
```

## Testing

### Backend Tests

```bash
cd backend

# Unit tests
go test ./internal/...

# Integration tests (requires running database)
go test ./tests/integration/...

# With race detection
go test -race ./...

# Specific package
go test ./internal/service

# Verbose output
go test -v ./...
```

### Frontend Tests

```bash
cd frontend

# Run tests (when implemented)
bun test

# Watch mode
bun test --watch

# Coverage
bun test --coverage
```

### E2E Tests

```bash
# Install Playwright
cd frontend
bun add -D @playwright/test

# Run E2E tests
bun playwright test

# Run in headed mode
bun playwright test --headed

# Run specific test
bun playwright test tests/e2e/auth.spec.ts
```

### API Testing with cURL

```bash
# Health check
curl http://localhost:8080/health

# Register user
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","name":"Test User"}'

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!"}'

# Get users (with auth token)
curl http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Docker Development

### Build and Run All Services

```bash
# Build images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v
```

### Rebuild After Code Changes

```bash
# Rebuild specific service
docker-compose up -d --build backend

# Rebuild all
docker-compose up -d --build
```

## Debugging

### Backend Debugging with Delve

```bash
# Install delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Run with debugger
dlv debug ./cmd/server/main.go

# Or attach to running process
dlv attach $(pgrep server)
```

### VS Code Debug Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Backend",
      "type": "go",
      "request": "launch",
      "mode": "debug",
      "program": "${workspaceFolder}/backend/cmd/server",
      "env": {
        "PORT": "8080"
      },
      "envFile": "${workspaceFolder}/backend/.env"
    },
    {
      "name": "Attach to Frontend",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "restart": true
    }
  ]
}
```

### Database Debugging

```bash
# Connect to database
psql -h localhost -U postgres -d skoservice

# List tables in schema
\dt authenserver_service.*

# Describe table
\d authenserver_service.users

# View data
SELECT * FROM authenserver_service.users LIMIT 10;

# Check indexes
\di authenserver_service.*

# Explain query performance
EXPLAIN ANALYZE SELECT * FROM authenserver_service.users WHERE email = 'test@example.com';
```

## Common Issues

### Port Already in Use

```bash
# Find process using port
lsof -i :8080
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Test connection
psql -h localhost -U postgres -d skoservice -c "SELECT 1;"

# Reset database
docker-compose down -v postgres
docker-compose up -d postgres
```

### Frontend Build Errors

```bash
# Clear Next.js cache
cd frontend
rm -rf .next

# Clear Bun cache
rm -rf node_modules
bun install

# Clear all caches
bun run clean  # if script exists
```

### Backend Module Issues

```bash
# Clean module cache
go clean -modcache

# Tidy dependencies
go mod tidy

# Download dependencies
go mod download
```

## Code Style & Best Practices

### Go Code Style

Follow [Effective Go](https://golang.org/doc/effective_go):
- Use `gofmt` for formatting
- Use meaningful variable names
- Write tests for all business logic
- Use interfaces for dependency injection
- Keep functions small and focused

### TypeScript Code Style

Follow [Airbnb Style Guide](https://github.com/airbnb/javascript):
- Use TypeScript strict mode
- Use functional components
- Use hooks for state management
- Keep components small
- Use proper typing

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes and commit
git add .
git commit -m "feat: add user profile page"

# Push and create PR
git push origin feature/my-feature
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Build process or auxiliary tools

## Resources

- [Go Documentation](https://go.dev/doc/)
- [Fiber Documentation](https://docs.gofiber.io/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Bun Documentation](https://bun.sh/docs)
- [sqlc Documentation](https://docs.sqlc.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

## Support

For development questions:
1. Check this documentation
2. Review the [Architecture Design](./architecture-design.md)
3. Check [Migration Guide](./migration-guide.md)
4. Create an issue on GitHub
5. Contact the development team
