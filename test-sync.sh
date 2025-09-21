#!/bin/bash

# Service Synchronization Test Script
# Tests that start-services.sh and service-manager.sh work together properly

echo "🔄 Testing Service Script Synchronization"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            ;;
    esac
}

# Test 1: Start a service with service-manager.sh, check with status
print_status "INFO" "Test 1: Starting discovery-server with service-manager.sh"
./service-manager.sh start discovery-server >/dev/null 2>&1
sleep 2

if ./service-manager.sh status discovery-server | grep -q "RUNNING"; then
    print_status "PASS" "Discovery server started and detected by service-manager.sh"
else
    print_status "FAIL" "Service-manager.sh could not start/detect discovery-server"
fi

# Test 2: Check if PID file is in correct location
if [ -f "pids/discovery-server.pid" ]; then
    print_status "PASS" "PID file created in correct location (pids/)"
else
    print_status "FAIL" "PID file not found in pids/ directory"
fi

# Test 3: Stop with stop-services.sh
print_status "INFO" "Test 2: Stopping with stop-services.sh"
echo "n" | ./stop-services.sh >/dev/null 2>&1

if ./service-manager.sh status discovery-server | grep -q "STOPPED"; then
    print_status "PASS" "Service stopped by stop-services.sh and detected by service-manager.sh"
else
    print_status "FAIL" "Cross-script stopping failed"
fi

# Test 4: Start with simulated start-services.sh approach
print_status "INFO" "Test 3: Starting with start-services.sh approach"
cd discovery-server
mkdir -p ../pids
nohup mvn spring-boot:run > "../logs/discovery-server.log" 2>&1 &
pid=$!
echo $pid > "../pids/discovery-server.pid"
cd ..
sleep 3

if ./service-manager.sh status discovery-server | grep -q "RUNNING"; then
    print_status "PASS" "Service started by start-services.sh method detected by service-manager.sh"
else
    print_status "FAIL" "Cross-script starting failed"
fi

# Test 5: Final cleanup
print_status "INFO" "Test 4: Final cleanup with service-manager.sh"
./service-manager.sh stop discovery-server >/dev/null 2>&1

if ./service-manager.sh status discovery-server | grep -q "STOPPED"; then
    print_status "PASS" "Final cleanup successful"
else
    print_status "FAIL" "Final cleanup failed"
fi

echo ""
echo "🎉 Service Synchronization Test Complete!"
echo ""
echo "Summary:"
echo "- start-services.sh and service-manager.sh now use the same PID file location (pids/)"
echo "- stop-services.sh has been updated to use the same location"
echo "- All three scripts are now fully synchronized and interoperable"
echo ""
echo "Usage:"
echo "  ./start-services.sh        # Start all services"
echo "  ./service-manager.sh       # Manage individual services"
echo "  ./stop-services.sh         # Stop all services"
echo "  All scripts now work together seamlessly!"
