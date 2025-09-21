#!/bin/bash

# Load Test Cleanup Script
# Cleans up resources after load balancing tests

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ;;
    esac
}

echo "🧹 Load Test Cleanup"
echo "===================="
echo ""

print_status "INFO" "Cleaning up load testing resources..."

# Stop all multi-instance services
print_status "INFO" "Stopping multi-instance services..."

services=("auth-service" "user-service" "product-service")

for service in "${services[@]}"; do
    print_status "INFO" "Checking for $service instances..."
    
    # Stop multiple instances
    instance_count=0
    for pid_file in pids/multi-instance/${service}-instance-*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            local instance_name=$(basename "$pid_file" .pid)
            
            if kill -0 "$pid" 2>/dev/null; then
                print_status "INFO" "Stopping $instance_name (PID: $pid)"
                kill "$pid"
                
                # Wait for graceful shutdown
                for i in {1..5}; do
                    if ! kill -0 "$pid" 2>/dev/null; then
                        break
                    fi
                    sleep 1
                done
                
                # Force kill if still running
                if kill -0 "$pid" 2>/dev/null; then
                    print_status "WARN" "Force killing $instance_name"
                    kill -9 "$pid"
                fi
                
                instance_count=$((instance_count + 1))
            fi
            
            rm -f "$pid_file"
        fi
    done
    
    if [ $instance_count -gt 0 ]; then
        print_status "PASS" "Stopped $instance_count instances of $service"
    else
        print_status "INFO" "No running instances of $service found"
    fi
done

# Clean up directories
print_status "INFO" "Cleaning up temporary directories..."

if [ -d "pids/multi-instance" ]; then
    rm -rf pids/multi-instance
    print_status "PASS" "Removed multi-instance PID files"
fi

if [ -d "logs/multi-instance" ]; then
    echo ""
    echo "Do you want to remove multi-instance log files? (y/N)"
    read -r remove_logs
    
    if [[ $remove_logs =~ ^[Yy]$ ]]; then
        rm -rf logs/multi-instance
        print_status "PASS" "Removed multi-instance log files"
    else
        print_status "INFO" "Kept multi-instance log files for review"
    fi
fi

# Clean up any temporary test files
print_status "INFO" "Cleaning up temporary test files..."
rm -rf /tmp/load_test_*
find /tmp -name "load_test_*" -type d -exec rm -rf {} + 2>/dev/null || true

# Check for any remaining Spring Boot processes
print_status "INFO" "Checking for remaining Spring Boot processes..."
spring_processes=$(ps aux | grep -E "(mvn spring-boot:run|java.*spring-boot)" | grep -v grep | wc -l)

if [ $spring_processes -gt 0 ]; then
    print_status "WARN" "Found $spring_processes Spring Boot processes still running"
    echo ""
    echo "Remaining processes:"
    ps aux | grep -E "(mvn spring-boot:run|java.*spring-boot)" | grep -v grep
    echo ""
    echo "Do you want to stop all Spring Boot processes? (y/N)"
    read -r stop_all
    
    if [[ $stop_all =~ ^[Yy]$ ]]; then
        pkill -f "mvn spring-boot:run" 2>/dev/null || true
        pkill -f "java.*spring-boot" 2>/dev/null || true
        sleep 2
        print_status "PASS" "Stopped all Spring Boot processes"
    fi
else
    print_status "PASS" "No additional Spring Boot processes found"
fi

# Show current service status
echo ""
print_status "INFO" "Current service status:"
./service-manager.sh status all 2>/dev/null || echo "Service manager not available"

echo ""
print_status "PASS" "Load test cleanup completed!"
echo ""
echo "📋 Summary:"
echo "- Stopped all multi-instance services"
echo "- Cleaned up temporary files and directories"
echo "- System is ready for normal operation"
echo ""
echo "🚀 To start normal services again:"
echo "   ./start-services.sh"
echo ""
echo "📊 To run load tests again:"
echo "   ./setup-load-test.sh"
echo "   ./test-load-balancing.sh"
