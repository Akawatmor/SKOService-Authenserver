# SKOService-Authenserver (SAuthenServer)

SAuthenServer is a centralized Authentication and Authorization service designed to secure various internal and external services. It acts as a single source of truth for user identity and access control (RBAC), utilizing Next.js (App Router) and Auth.js.

## 🚀 Features

- **Centralized Authentication**: Single Sign-On (SSO) capabilities for multiple client services.
- **Multiple Providers**: Support for Credentials, Google, GitHub, and Cloudflare Access.
- **RBAC**: Role-Based Access Control management.
- **Modern Stack**: Built with Next.js 14, TypeScript, Tailwind CSS, and Prisma.

## 🛠 Technology Stack

### Frontend
- **Framework:** [Next.js 15](https://nextjs.org/) (App Router)
- **Runtime:** [Bun](https://bun.sh/) - High-performance JavaScript runtime
- **Language:** TypeScript
- **Styling:** Tailwind CSS
- **UI Components:** Shadcn/ui

### Backend
- **Language:** [Go (Golang)](https://go.dev/)
- **Framework:** [Fiber](https://gofiber.io/) - Express-inspired web framework
- **Database:** PostgreSQL
- **Database Toolkit:** [sqlc](https://sqlc.dev/) - Type-safe SQL code generation
- **Cache:** Redis - In-memory data structure store
- **Authentication:** [PASETO](https://paseto.io/) (Platform-Agnostic Security Tokens) + OAuth2
- **API Documentation:** Swagger/OpenAPI 3.0

### Infrastructure
- **Containerization:** Docker + Docker Compose
- **Reverse Proxy:** Traefik - Cloud-native edge router
- **Deployment:** Docker / Proxmox LXC
- **CI/CD:** GitHub Actions

## 📂 Documentation

- [Architecture Design](docs/architecture-design.md)
- [CI/CD Process](docs/cicd-process.md)
- [Database Schema](docs/database-schema.md)

## 🏁 Getting Started

### Prerequisites

- [Bun](https://bun.sh/) (v1.0+)
- [Go](https://go.dev/) (v1.22+)
- [Docker](https://www.docker.com/) & Docker Compose
- PostgreSQL Database (or use Docker Compose)
- Redis (or use Docker Compose)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd SKOServFrontend dependencies:**
   ```bash
   cd frontend
   bun install
   ```

3. **Install Backend dependencies:**
   ```bash
   cd backend
   go mod download
   ```

4  npm install
   ````.env` files:
   
   **Backend (.env in `/backend`):**
   ```env
   # Database
   DATABASE_URL=postgresql://user:password@localhost:5432/skoservice?sslmode=disable
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=user
   DB_PASSWORD=password
   DB_NAME=skoservice
   DB_SCHEMA=authenserver_service
   
   # Redis
   REDIS_URL=redis://localhost:6379
   REDIS_PASSWORD=
   
   # Server
   PORT=8080
   ENVIRONMENT=development
   
   # Auth
   PASETO_SECRET_KEY=your-32-byte-secret-key-here
   OAUTH_GOOGLE_CLIENT_ID=your-google-client-id
   OAUTH_GOOGLE_CLIENT_SECRET=your-google-client-secret
   OAUTH_GITHUB_CLIENT_ID=your-github-client-id
   OAUTH_GITHUB_CLIENT_SECRET=your-github-client-secret
   ```
   
   **Frontend (.env.local in `/frontend`):**
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:8080/api
   ```

5. **Run with Docker Compose (Recommended):**
   ```bash
   docker-compose up -d
   ```
   
   Or run services individually:
   
   **Backend:**
   ```bash
   cd backend
   go run cmd/server/main.go
   ```
   
   **Frontend:**
   ```bash
   cd frontend
   bun dev
   ```

   - Frontend: [http://localhost:3000](http://localhost:3000)
   - Backend API: [http://localhost:8080](http://localhost:8080)
   - API Documentation: [http://localhost:8080/swagger](http://localhost:8080/swagger)

## 📜 Scripts

### Frontend
- `bun dev`: Runs the Next.js app in development mode
- `bun build`: Builds the application for production
- `bun start`: Starts the production build
- `bun lint`: Runs ESLint

### Backend
- `go run cmd/server/main.go`: Run the Go server
- `go test ./...`: Run all tests
- `make sqlc`: Generate type-safe Go code from SQL
- `make migrate-up`: Run database migrations
- `make migrate-down`: Rollback database migrations
- `make swagger`: Generate Swagger documentation your browser to see the result.

## 📜 Scripts

- `npm run dev`: Runs the application in development mode.
- `npm run build`: Builds the application for production.
- `npm start`: Starts the production build.
- `npm lint`: Runs ESLint to check for code quality issues.
