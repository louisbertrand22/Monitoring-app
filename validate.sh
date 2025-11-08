#!/bin/bash

# Validation script for the monitoring app configuration
# This script checks that all configuration files are valid

set -e

echo "🔍 Validating Monitoring App Configuration..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print success
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print info
info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if Docker is installed
info "Checking Docker installation..."
if command -v docker &> /dev/null; then
    success "Docker is installed ($(docker --version))"
else
    error "Docker is not installed"
    exit 1
fi

# Check if Docker Compose is installed
info "Checking Docker Compose installation..."
if docker compose version &> /dev/null; then
    success "Docker Compose is installed ($(docker compose version))"
else
    error "Docker Compose is not installed"
    exit 1
fi

# Validate docker-compose.yml
info "Validating docker-compose.yml..."
if docker compose config > /dev/null 2>&1; then
    success "docker-compose.yml is valid"
else
    error "docker-compose.yml has errors"
    exit 1
fi

# Validate Prometheus configuration
info "Validating Prometheus configuration..."
if docker run --rm --entrypoint=/bin/promtool -v $(pwd)/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest check config /etc/prometheus/prometheus.yml > /dev/null 2>&1; then
    success "prometheus.yml is valid"
else
    error "prometheus.yml has errors"
    exit 1
fi

# Validate YAML files using Python
info "Validating YAML files..."
python3 -c "
import yaml
import sys

files = [
    'blackbox/blackbox.yml',
    'grafana/provisioning/datasources/prometheus.yml',
    'grafana/provisioning/dashboards/default.yml'
]

all_valid = True
for file in files:
    try:
        with open(file, 'r') as f:
            yaml.safe_load(f)
        print(f'  ✓ {file}')
    except Exception as e:
        print(f'  ✗ {file}: {e}')
        all_valid = False

sys.exit(0 if all_valid else 1)
"

if [ $? -eq 0 ]; then
    success "All YAML files are valid"
else
    error "Some YAML files have errors"
    exit 1
fi

# Validate JSON files
info "Validating JSON files..."
if python3 -m json.tool grafana/dashboards/website-monitoring.json > /dev/null 2>&1; then
    success "website-monitoring.json is valid"
else
    error "website-monitoring.json has errors"
    exit 1
fi

# Check required files exist
info "Checking required files..."
required_files=(
    "docker-compose.yml"
    "prometheus/prometheus.yml"
    "blackbox/blackbox.yml"
    "grafana/provisioning/datasources/prometheus.yml"
    "grafana/provisioning/dashboards/default.yml"
    "grafana/dashboards/website-monitoring.json"
    "README.md"
    "DEPLOYMENT.md"
    ".env.example"
    ".gitignore"
)

all_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        success "Found: $file"
    else
        error "Missing: $file"
        all_exist=false
    fi
done

if [ "$all_exist" = false ]; then
    exit 1
fi

# Check directory structure
info "Checking directory structure..."
required_dirs=(
    "prometheus"
    "grafana/provisioning/datasources"
    "grafana/provisioning/dashboards"
    "grafana/dashboards"
    "blackbox"
)

all_exist=true
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        success "Found: $dir/"
    else
        error "Missing: $dir/"
        all_exist=false
    fi
done

if [ "$all_exist" = false ]; then
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All validation checks passed!${NC}"
echo ""
echo "The monitoring app is ready to be deployed."
echo "Run 'docker compose up -d' to start the services."
