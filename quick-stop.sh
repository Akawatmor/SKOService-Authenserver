#!/bin/bash

# SAuthenServer Quick Stop Script
# This script stops and optionally removes all containers, volumes, and networks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           SAuthenServer - Quick Stop Script               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Parse command line arguments
REMOVE_VOLUMES=false
REMOVE_IMAGES=false
REMOVE_ALL=false

show_help() {
    echo "Usage: ./quick-stop.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --volumes    Remove all volumes (WARNING: deletes all data)"
    echo "  -i, --images     Remove all project images"
    echo "  -a, --all        Remove everything (containers, volumes, images, networks)"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./quick-stop.sh           # Stop containers only"
    echo "  ./quick-stop.sh -v        # Stop and remove volumes"
    echo "  ./quick-stop.sh -a        # Remove everything"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        -i|--images)
            REMOVE_IMAGES=true
            shift
            ;;
        -a|--all)
            REMOVE_ALL=true
            REMOVE_VOLUMES=true
            REMOVE_IMAGES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Confirmation for destructive operations
if [ "$REMOVE_VOLUMES" = true ] || [ "$REMOVE_ALL" = true ]; then
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  WARNING: This will DELETE ALL DATA in volumes!          ║${NC}"
    echo -e "${RED}║  - PostgreSQL database                                    ║${NC}"
    echo -e "${RED}║  - Redis cache                                            ║${NC}"
    echo -e "${RED}║  - Prometheus metrics                                     ║${NC}"
    echo -e "${RED}║  - Grafana dashboards and settings                        ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_warning "Operation cancelled."
        exit 0
    fi
fi

echo ""
print_status "Stopping SAuthenServer services..."

# Step 0: Stop backend and frontend processes
echo ""
echo -e "${YELLOW}Step 0: Stopping backend and frontend processes...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.running_pids"

if [ -f "$PID_FILE" ]; then
    while IFS=: read -r name pid; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            print_success "Stopped $name (PID: $pid)"
        else
            print_warning "$name (PID: $pid) was not running"
        fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
else
    print_warning "No PID file found. Trying to find processes by name..."
fi

# Kill any remaining Go server processes
pkill -f "go run cmd/server/main.go" 2>/dev/null && print_success "Stopped Go backend process" || true

# Kill any remaining bun dev processes  
pkill -f "bun dev" 2>/dev/null && print_success "Stopped Bun frontend process" || true

# Also kill any node processes on port 3000 (Next.js)
lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null && print_success "Stopped process on port 3000" || true

# Kill any process on port 8080 (backend)
lsof -ti:8080 2>/dev/null | xargs kill -9 2>/dev/null && print_success "Stopped process on port 8080" || true

print_success "Application processes stopped"

# Step 1: Stop all Docker containers
echo ""
echo -e "${YELLOW}Step 1: Stopping Docker containers...${NC}"
if docker-compose ps -q > /dev/null 2>&1; then
    docker-compose stop
    print_success "Containers stopped"
else
    print_warning "No running containers found"
fi

# Step 2: Remove containers
echo ""
echo -e "${YELLOW}Step 2: Removing containers...${NC}"
docker-compose down 2>/dev/null || true
print_success "Containers removed"

# Step 3: Remove volumes if requested
if [ "$REMOVE_VOLUMES" = true ]; then
    echo ""
    echo -e "${YELLOW}Step 3: Removing volumes...${NC}"
    docker-compose down -v 2>/dev/null || true
    
    # Also remove any orphaned volumes
    docker volume ls -q | grep -E "skoservice|sauthen" | xargs -r docker volume rm 2>/dev/null || true
    print_success "Volumes removed"
fi

# Step 4: Remove images if requested
if [ "$REMOVE_IMAGES" = true ]; then
    echo ""
    echo -e "${YELLOW}Step 4: Removing images...${NC}"
    
    # Remove project-specific images
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "skoservice|sauthen" | xargs -r docker rmi -f 2>/dev/null || true
    
    # Remove dangling images
    docker image prune -f 2>/dev/null || true
    print_success "Images removed"
fi

# Step 5: Remove networks if all cleanup requested
if [ "$REMOVE_ALL" = true ]; then
    echo ""
    echo -e "${YELLOW}Step 5: Removing networks...${NC}"
    docker network ls -q --filter "name=sauthen" | xargs -r docker network rm 2>/dev/null || true
    print_success "Networks removed"
    
    echo ""
    echo -e "${YELLOW}Step 6: Pruning unused Docker resources...${NC}"
    docker system prune -f 2>/dev/null || true
    print_success "Docker resources pruned"
fi

# Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              SAuthenServer Stopped Successfully           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$REMOVE_ALL" = true ]; then
    echo -e "${GREEN}✓${NC} All containers, volumes, images, and networks removed"
    echo ""
    echo "To start fresh, run:"
    echo -e "  ${BLUE}./quick-start.sh${NC}"
elif [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${GREEN}✓${NC} Containers and volumes removed"
    echo -e "${YELLOW}!${NC} All data has been deleted"
    echo ""
    echo "To start fresh, run:"
    echo -e "  ${BLUE}./quick-start.sh${NC}"
elif [ "$REMOVE_IMAGES" = true ]; then
    echo -e "${GREEN}✓${NC} Containers and images removed"
    echo -e "${GREEN}✓${NC} Volumes preserved (data intact)"
    echo ""
    echo "To restart services, run:"
    echo -e "  ${BLUE}docker-compose up -d --build${NC}"
else
    echo -e "${GREEN}✓${NC} Containers stopped and removed"
    echo -e "${GREEN}✓${NC} Volumes preserved (data intact)"
    echo -e "${GREEN}✓${NC} Images preserved (faster restart)"
    echo ""
    echo "To restart services, run:"
    echo -e "  ${BLUE}docker-compose up -d${NC}"
    echo ""
    echo "To remove all data, run:"
    echo -e "  ${BLUE}./quick-stop.sh --all${NC}"
fi

echo ""
