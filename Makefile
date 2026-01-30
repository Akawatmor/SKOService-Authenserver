.PHONY: help build run test clean sqlc migrate-up migrate-down migrate-create swagger docker-build docker-up docker-down

# Default target
help:
	@echo "Available targets:"
	@echo "  build         - Build the Go binary"
	@echo "  run           - Run the application"
	@echo "  test          - Run tests"
	@echo "  clean         - Clean build artifacts"
	@echo "  sqlc          - Generate Go code from SQL queries"
	@echo "  migrate-up    - Run database migrations"
	@echo "  migrate-down  - Rollback database migrations"
	@echo "  swagger       - Generate Swagger documentation"
	@echo "  docker-build  - Build Docker image"
	@echo "  docker-up     - Start Docker containers"
	@echo "  docker-down   - Stop Docker containers"

# Build the application
build:
	@echo "Building application..."
	cd backend && go build -o ../bin/server cmd/server/main.go

# Run the application
run:
	@echo "Running application..."
	cd backend && go run cmd/server/main.go

# Run tests
test:
	@echo "Running tests..."
	cd backend && go test -v ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf bin/
	rm -rf backend/internal/db/*.go

# Generate Go code from SQL using sqlc
sqlc:
	@echo "Generating sqlc code..."
	sqlc generate

# Run database migrations (using golang-migrate)
migrate-up:
	@echo "Running migrations..."
	migrate -path backend/db/schema -database "${DATABASE_URL}" -verbose up

migrate-down:
	@echo "Rolling back migrations..."
	migrate -path backend/db/schema -database "${DATABASE_URL}" -verbose down

# Create a new migration
migrate-create:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir backend/db/schema -seq $$name

# Generate Swagger documentation
swagger:
	@echo "Generating Swagger docs..."
	cd backend && swag init -g cmd/server/main.go -o docs

# Format Swagger documentation
swagger-fmt:
	@echo "Formatting Swagger annotations..."
	cd backend && swag fmt

# Docker commands
docker-build:
	@echo "Building Docker images..."
	docker-compose build

docker-up:
	@echo "Starting Docker containers..."
	docker-compose up -d

docker-down:
	@echo "Stopping Docker containers..."
	docker-compose down

# Install development tools
install-tools:
	@echo "Installing development tools..."
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
	go install github.com/swaggo/swag/cmd/swag@latest
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
