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

if grep -q "your-32-byte-secret-key" backend/.env 2>/dev/null; then
    SECRET=$(openssl rand -base64 32)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/your-32-byte-secret-key-here-replace-this/$SECRET/" backend/.env
    else
        sed -i "s/your-32-byte-secret-key-here-replace-this/$SECRET/" backend/.env
    fi
    print_success "Generated PASETO secret key"
else
    print_info "PASETO secret key already configured"
fi

echo ""

# Step 4: Start infrastructure services
echo "Step 4: Starting infrastructure services..."
echo "-------------------------------------------"

print_info "Starting PostgreSQL and Redis..."
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

echo ""

# Step 5: Install backend dependencies
echo "Step 5: Installing backend dependencies..."
echo "------------------------------------------"

cd backend
go mod download
print_success "Backend dependencies installed"
cd ..

echo ""

# Step 6: Generate sqlc code
echo "Step 6: Generating database code with sqlc..."
echo "----------------------------------------------"

if command_exists sqlc; then
    sqlc generate
    print_success "Generated sqlc code"
else
    print_warning "sqlc not installed. Installing now..."
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
    export PATH=$PATH:$(go env GOPATH)/bin
    sqlc generate
    print_success "Installed sqlc and generated code"
fi

echo ""

# Step 7: Apply database schema
echo "Step 7: Applying database schema..."
echo "-----------------------------------"

print_info "Applying schema to PostgreSQL..."
docker-compose exec -T postgres psql -U postgres -d skoservice < backend/db/schema/001_init.sql > /dev/null 2>&1 || {
    print_warning "Schema may already exist, continuing..."
}
print_success "Database schema applied"

echo ""

# Step 8: Install frontend dependencies
echo "Step 8: Installing frontend dependencies..."
echo "-------------------------------------------"

cd frontend
bun install
print_success "Frontend dependencies installed"
cd ..

echo ""

# Step 9: Display next steps
echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "🎯 Next Steps:"
echo ""
echo "1️⃣  Configure OAuth providers (optional):"
echo "   - Edit backend/.env"
echo "   - Set OAUTH_GOOGLE_CLIENT_ID and OAUTH_GOOGLE_CLIENT_SECRET"
echo "   - Set OAUTH_GITHUB_CLIENT_ID and OAUTH_GITHUB_CLIENT_SECRET"
echo ""
echo "2️⃣  Start the backend:"
echo "   cd backend"
echo "   go run cmd/server/main.go"
echo ""
echo "3️⃣  In a new terminal, start the frontend:"
echo "   cd frontend"
echo "   bun dev"
echo ""
echo "4️⃣  Access the application:"
echo "   Frontend:  http://localhost:3000"
echo "   Backend:   http://localhost:8080"
echo "   API Docs:  http://localhost:8080/swagger/index.html"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Project overview"
echo "   - MIGRATION-SUMMARY.md - What changed"
echo "   - docs/development-setup.md - Detailed setup guide"
echo "   - docs/architecture-design.md - System architecture"
echo ""
echo "🐳 Alternative: Run everything with Docker:"
echo "   docker-compose up -d"
echo "   (Then access the same URLs as above)"
echo ""
echo "💡 Tip: Run 'make help' to see all available commands"
echo ""
echo "Happy coding! 🚀"
echo ""
