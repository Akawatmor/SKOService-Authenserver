#!/bin/bash

# Quick Start Script for SKOService-Authenserver
# This script helps you get the project running quickly

set -e

echo "🚀 SKOService-Authenserver Quick Start"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print colored message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo "ℹ $1"
}

# Step 1: Check prerequisites
echo "Step 1: Checking prerequisites..."
echo "--------------------------------"

MISSING_DEPS=0

if command_exists bun; then
    print_success "Bun is installed ($(bun --version))"
else
    print_error "Bun is not installed"
    echo "  Install: curl -fsSL https://bun.sh/install | bash"
    MISSING_DEPS=1
fi

if command_exists go; then
    print_success "Go is installed ($(go version | awk '{print $3}'))"
else
    print_error "Go is not installed"
    echo "  Install: https://go.dev/dl/"
    MISSING_DEPS=1
fi

if command_exists docker; then
    print_success "Docker is installed ($(docker --version | awk '{print $3}' | sed 's/,//'))"
else
    print_error "Docker is not installed"
    echo "  Install: https://docs.docker.com/get-docker/"
    MISSING_DEPS=1
fi

if command_exists docker-compose; then
    print_success "Docker Compose is installed"
else
    print_error "Docker Compose is not installed"
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    print_error "Please install missing dependencies and run this script again"
    exit 1
fi

echo ""

# Step 2: Setup environment files
echo "Step 2: Setting up environment files..."
echo "---------------------------------------"

if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env
    print_success "Created backend/.env"
    print_warning "Please edit backend/.env and set your configuration"
else
    print_info "backend/.env already exists"
fi

if [ ! -f frontend/.env.local ]; then
    cp frontend/.env.example frontend/.env.local
    print_success "Created frontend/.env.local"
else
    print_info "frontend/.env.local already exists"
fi

echo ""

# Step 3: Generate PASETO secret if needed
echo "Step 3: Generating PASETO secret key..."
echo "----------------------------------------"

if grep -q "your-32-byte-secret-key-replace-me-please-now" backend/.env 2>/dev/null; then
    SECRET=$(openssl rand -base64 32)
    # Use printf with %s to avoid sed delimiter issues
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|your-32-byte-secret-key-replace-me-please-now|$SECRET|" backend/.env
    else
        sed -i "s|your-32-byte-secret-key-replace-me-please-now|$SECRET|" backend/.env
    fi
    print_success "Generated PASETO secret key"
else
    print_info "PASETO secret key already configured"
fi

echo ""

# Step 4: Checking database connection...
echo "Step 4: Checking database connection..."
echo "----------------------------------------"

# Load database credentials from .env
if [ -f backend/.env ]; then
    DB_HOST=$(grep "^DB_HOST=" backend/.env | cut -d '=' -f2)
    DB_PORT=$(grep "^DB_PORT=" backend/.env | cut -d '=' -f2)
    DB_USER=$(grep "^DB_USER=" backend/.env | cut -d '=' -f2)
    DB_PASSWORD=$(grep "^DB_PASSWORD=" backend/.env | cut -d '=' -f2)
    DB_NAME=$(grep "^DB_NAME=" backend/.env | cut -d '=' -f2)
fi

# Check if using remote database
if [ "$DB_HOST" != "localhost" ] && [ "$DB_HOST" != "127.0.0.1" ]; then
    print_warning "Using remote database at $DB_HOST:$DB_PORT"
    print_info "Skipping local PostgreSQL/Redis setup"
    print_info "Make sure database is accessible"
    
    # Test connection
    if command_exists psql; then
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
            print_success "Remote database connection successful"
        else
            print_error "Cannot connect to remote database at $DB_HOST:$DB_PORT"
            print_error "Please check your VPN connection and database credentials"
            exit 1
        fi
    else
        print_warning "psql not installed. Skipping database connection test."
        print_warning "Install with: brew install postgresql (macOS) or apt-get install postgresql-client (Linux)"
    fi
else
    print_info "Starting local PostgreSQL and Redis..."
    docker-compose up -d postgres redis

    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to be ready..."
    sleep 5

    until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    echo ""
    print_success "PostgreSQL is ready"
    print_success "Redis is running"
fi

echo ""

# Step 5: Installing backend dependencies...
echo "Step 5: Installing backend dependencies..."
echo "------------------------------------------"

cd backend
go mod download
print_success "Backend dependencies installed"
cd ..

echo ""

# Step 6: Apply database schema (before sqlc)
echo "Step 6: Applying database schema..."
echo "------------------------------------"

if [ "$DB_HOST" != "localhost" ] && [ "$DB_HOST" != "127.0.0.1" ]; then
    print_info "Applying schema to remote database at $DB_HOST..."
    if command_exists psql; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f backend/db/schema/001_init_with_migrations.sql > /dev/null 2>&1 && {
            print_success "Database schema applied to remote database"
        } || {
            print_warning "Schema may already exist or check failed, continuing..."
        }
    else
        print_warning "psql not installed. Please apply schema manually:"
        print_warning "PGPASSWORD=<password> psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f backend/db/schema/001_init_with_migrations.sql"
    fi
else
    print_info "Applying schema to local PostgreSQL..."
    docker-compose exec -T postgres psql -U postgres -d skoservice < backend/db/schema/001_init_with_migrations.sql > /dev/null 2>&1 || {
        print_warning "Schema may already exist, continuing..."
    }
    print_success "Database schema applied"
fi

echo ""

# Step 7: Generating database code with sqlc...
echo "Step 7: Generating database code with sqlc..."
echo "----------------------------------------------"

# Load DATABASE_URL for sqlc
if [ -f backend/.env ]; then
    export DATABASE_URL=$(grep "^DATABASE_URL=" backend/.env | cut -d '=' -f2)
fi

if command_exists sqlc; then
    sqlc generate
    print_success "Generated sqlc code"
else
    print_warning "sqlc not installed. Installing now..."
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
    export PATH=$PATH:$(go env GOPATH)/bin
    $(go env GOPATH)/bin/sqlc generate
    print_success "Installed sqlc and generated code"
fi

echo ""

# Step 8: Install frontend dependencies
echo "Step 8: Installing frontend dependencies..."
echo "-------------------------------------------"

cd frontend
bun install
print_success "Frontend dependencies installed"
cd ..

echo ""

# Step 9: Start services
echo "Step 9: Starting services..."
echo "----------------------------"

# Create logs directory
mkdir -p logs

# Store PIDs for stopping later
PID_FILE=".running_pids"
> "$PID_FILE"

# Start backend
print_info "Starting backend server..."
cd backend
nohup go run ./cmd/server > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "backend:$BACKEND_PID" >> "../$PID_FILE"
cd ..
sleep 2

# Check if backend started successfully
if kill -0 $BACKEND_PID 2>/dev/null; then
    print_success "Backend started (PID: $BACKEND_PID)"
else
    print_error "Backend failed to start. Check logs/backend.log for details"
fi

# Start frontend
print_info "Starting frontend server..."
cd frontend
nohup bun dev > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "frontend:$FRONTEND_PID" >> "../$PID_FILE"
cd ..
sleep 2

# Check if frontend started successfully
if kill -0 $FRONTEND_PID 2>/dev/null; then
    print_success "Frontend started (PID: $FRONTEND_PID)"
else
    print_error "Frontend failed to start. Check logs/frontend.log for details"
fi

echo ""
echo "=========================================="
echo "✅ All Services Running!"
echo "=========================================="
echo ""
echo "🌐 Access the application:"
echo "   Frontend:  http://localhost:3000"
echo "   Backend:   http://localhost:8080"
echo "   API Docs:  http://localhost:8080/swagger/index.html"
echo ""
echo "📋 Logs:"
echo "   Backend:   tail -f logs/backend.log"
echo "   Frontend:  tail -f logs/frontend.log"
echo ""
echo "🛑 To stop all services:"
echo "   ./quick-stop.sh"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Project overview"
echo "   - MIGRATION-SUMMARY.md - What changed"
echo "   - docs/development-setup.md - Detailed setup guide"
echo "   - docs/architecture-design.md - System architecture"
echo ""
echo "Happy coding! 🚀"
echo ""
