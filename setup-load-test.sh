#!/bin/bash

# Load Balancing Setup Helper Script
# Prepares the environment for load balancing tests

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ;;
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ;;
    esac
}

echo "🔧 Load Balancing Test Environment Setup"
echo "========================================"
echo ""

print_status "INFO" "This script helps prepare your environment for load balancing tests"
echo ""

# Check current service status
print_status "INFO" "Checking current service status..."
./service-manager.sh status all

echo ""
print_status "INFO" "Available Load Balancing Test Options:"
echo ""
echo "1. � Test with multiple User Service instances"
echo "   - Starts 3 instances of User Service"
echo "   - Tests load distribution across user service instances"
echo "   - Good for testing user-specific load balancing"
echo ""
echo "2. 📦 Test with multiple Product Service instances"
echo "   - Starts 3 instances of Product Service"
echo "   - Tests load distribution across product service instances"
echo "   - Good for testing product-specific load balancing"
echo ""
echo "3. ⚡ Concurrent load test"
echo "   - Simulates multiple concurrent users"
echo "   - Performance benchmarking and stress testing"
echo "   - Measures response times and success rates"
echo ""
echo "4. � Full comprehensive test (Recommended)"
echo "   - Combines multiple instance testing + concurrent load"
echo "   - Most thorough load balancing validation"
echo "   - Complete performance analysis and reporting"
echo ""
echo "5. � Test existing instances (Quick start)"
echo "   - Uses currently running service instances"
echo "   - No additional setup required"
echo "   - Good for basic functionality validation"
echo ""

# Check if services are running
gateway_running=$(./service-manager.sh status api-gateway | grep -q "RUNNING" && echo "true" || echo "false")
discovery_running=$(./service-manager.sh status discovery-server | grep -q "RUNNING" && echo "true" || echo "false")

if [ "$gateway_running" = "false" ] || [ "$discovery_running" = "false" ]; then
    print_status "WARN" "Core services (Gateway/Discovery) are not running"
    echo ""
    echo "Would you like to start the basic services first? (y/N)"
    read -r start_services
    
    if [[ $start_services =~ ^[Yy]$ ]]; then
        print_status "INFO" "Starting core services..."
        ./service-manager.sh start discovery-server
        sleep 5
        ./service-manager.sh start api-gateway
        sleep 3
        ./service-manager.sh start auth-service
        sleep 2
        
        print_status "PASS" "Core services started"
    fi
fi

echo ""
print_status "INFO" "Environment Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Run the load balancing test:"
echo "   ./test-load-balancing.sh"
echo ""
echo "2. Available Test Options:"
echo "   Option 1: Test with multiple User Service instances"
echo "   Option 2: Test with multiple Product Service instances"
echo "   Option 3: Concurrent load test (performance benchmarking)"
echo "   Option 4: Full comprehensive test (recommended for complete evaluation)"
echo "   Option 5: Test existing instances (quick test without additional setup)"
echo ""
echo "3. Monitor services during testing:"
echo "   - Eureka Dashboard: http://localhost:8761"
echo "   - Service logs: tail -f logs/multi-instance/*.log"
echo "   - Service status: ./service-manager.sh status all"
echo ""
echo "4. Load Testing Tips:"
echo "   - 🚀 Beginners: Start with Option 5 (existing instances) for quick validation"
echo "   - 🎯 Focused Testing: Use Option 1 or 2 for specific service load balancing"
echo "   - 🔥 Performance: Use Option 3 for concurrent user simulation and benchmarking"
echo "   - 📊 Complete Evaluation: Use Option 4 for comprehensive load balancing analysis"
echo "   - 💻 Resource Monitoring: Watch CPU, memory usage during tests"
echo "   - ⚖️ Balance Check: Look for even request distribution across instances"
echo ""

# Check system resources
echo "💻 Current System Resources:"
echo "============================"
echo "Memory usage:"
free -h | head -2
echo ""
echo "CPU info:"
nproc
echo ""
echo "Available disk space:"
df -h . | tail -1
echo ""

print_status "INFO" "System appears ready for load balancing tests"
echo ""
echo "🚀 Ready to run: ./test-load-balancing.sh"
