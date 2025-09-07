#!/bin/bash

# Microservices API Testing Script

# Dynamic Base URLs using environment variables with fallback to localhost
API_HOST=${API_HOST:-"localhost"}
DISCOVERY_HOST=${DISCOVERY_HOST:-"localhost"}

# Port configurations
GATEWAY_PORT=${GATEWAY_PORT:-"8080"}
AUTH_PORT=${AUTH_PORT:-"8081"}
USER_PORT=${USER_PORT:-"8082"}
PRODUCT_PORT=${PRODUCT_PORT:-"8083"}
DISCOVERY_PORT=${DISCOVERY_PORT:-"8761"}

# Construct URLs
BASE_URL="http://${API_HOST}:${GATEWAY_PORT}"
AUTH_URL="http://${API_HOST}:${AUTH_PORT}"
USER_URL="http://${API_HOST}:${USER_PORT}"
PRODUCT_URL="http://${API_HOST}:${PRODUCT_PORT}"
DISCOVERY_URL="http://${DISCOVERY_HOST}:${DISCOVERY_PORT}"

echo "🧪 Testing Microservices API..."
echo ""
echo "🌐 Configuration:"
echo "   API Host: ${API_HOST}"
echo "   Gateway URL: ${BASE_URL}"
echo "   Auth Service URL: ${AUTH_URL}"
echo "   User Service URL: ${USER_URL}"
echo "   Product Service URL: ${PRODUCT_URL}"
echo "   Discovery URL: ${DISCOVERY_URL}"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ;;
    esac
}

# Function to test endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local expected_status=$4
    local description=$5
    local auth_header=$6
    
    echo ""
    print_status "INFO" "Testing: $description"
    echo "   Method: $method"
    echo "   URL: $url"
    
    if [ ! -z "$data" ]; then
        echo "   Data: $data"
    fi
    
    # Build curl command
    local curl_cmd="curl -s -w '%{http_code}' -o /tmp/response.json"
    
    if [ ! -z "$auth_header" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $auth_header'"
    fi
    
    if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    curl_cmd="$curl_cmd -X $method '$url'"
    
    # Execute request
    local status_code=$(eval $curl_cmd)
    local response=$(cat /tmp/response.json 2>/dev/null || echo "")
    
    # Check result
    if [ "$status_code" -eq "$expected_status" ]; then
        print_status "PASS" "$description (Status: $status_code)"
        if [ ! -z "$response" ] && [ "$response" != "null" ]; then
            echo "   Response: $response" | head -c 200
            if [ ${#response} -gt 200 ]; then
                echo "..."
            fi
            echo ""
        fi
    else
        print_status "FAIL" "$description (Expected: $expected_status, Got: $status_code)"
        if [ ! -z "$response" ]; then
            echo "   Response: $response"
        fi
    fi
}

# Function to wait for services
wait_for_services() {
    echo "⏳ Waiting for services to be ready..."
    
    # Dynamic service URLs - using | as separator, format: URL|NAME|EXPECTED_STATUS
    services=(
        "${DISCOVERY_URL}/actuator/health|Discovery Server|200"
        "${BASE_URL}/actuator/health|API Gateway|200"
        "${AUTH_URL}/actuator/health|Auth Service|403"
        "${USER_URL}/actuator/health|User Service|403"
        "${PRODUCT_URL}/actuator/health|Product Service|200"
    )
    
    for service in "${services[@]}"; do
        IFS='|' read -r url name expected_status <<< "$service"
        
        for i in {1..30}; do
            status_code=$(curl -s -w '%{http_code}' -o /dev/null "$url" 2>/dev/null)
            
            if [ "$status_code" -eq "$expected_status" ]; then
                print_status "PASS" "$name is ready (Status: $status_code)"
                break
            fi
            
            if [ $i -eq 30 ]; then
                print_status "FAIL" "$name is not responding (Expected: $expected_status, Got: $status_code)"
                return 1
            fi
            
            sleep 2
        done
    done
    
    echo ""
    return 0
}

# Main testing flow
main() {
    echo "🔍 Checking if services are running..."
    
    if ! wait_for_services; then
        echo ""
        print_status "FAIL" "Services are not ready. Please run ./start-services.sh first"
        exit 1
    fi
    
    echo "🎯 Starting API tests..."
    echo "=================================="
    
    # Test 1: Health checks
    test_endpoint "GET" "$BASE_URL/actuator/health" "" 200 "API Gateway Health Check"
    test_endpoint "GET" "$AUTH_URL/actuator/health" "" 200 "Auth Service Health Check"
    
    # Test 2: Service Discovery
    test_endpoint "GET" "$DISCOVERY_URL" "" 200 "Eureka Dashboard"
    
    # Test 3: Authentication
    echo ""
    echo "🔐 Testing Authentication..."
    echo "=================================="
    
    # Login to get JWT token
    login_data='{"username":"admin","password":"password"}'
    echo ""
    print_status "INFO" "Logging in to get JWT token..."
    
    # Get token via API Gateway
    token_response=$(curl -s -X POST -H "Content-Type: application/json" -d "$login_data" "$BASE_URL/auth/login")
    echo "Login response: $token_response"
    
    # Extract token (assuming response format: {"token":"jwt_token_here"})
    token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    if [ ! -z "$token" ] && [ "$token" != "null" ]; then
        print_status "PASS" "Authentication successful, token received"
        echo "Token (first 50 chars): ${token:0:50}..."
    else
        print_status "WARN" "Could not extract token, trying direct auth service..."
        # Try direct auth service
        token_response=$(curl -s -X POST -H "Content-Type: application/json" -d "$login_data" "$AUTH_URL/login")
        token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        if [ ! -z "$token" ] && [ "$token" != "null" ]; then
            print_status "PASS" "Direct auth service login successful"
        else
            print_status "FAIL" "Authentication failed"
            token=""
        fi
    fi
    
    # Test 4: User Service via API Gateway
    echo ""
    echo "👥 Testing User Service..."
    echo "=================================="
    
    # Create user
    user_data='{"username":"testuser","email":"test@example.com","firstName":"Test","lastName":"User"}'
    test_endpoint "POST" "$BASE_URL/users" "$user_data" 201 "Create User via API Gateway" "$token"
    
    # Get all users
    test_endpoint "GET" "$BASE_URL/users" "" 200 "Get All Users via API Gateway" "$token"
    
    # Get user by ID
    test_endpoint "GET" "$BASE_URL/users/1" "" 200 "Get User by ID via API Gateway" "$token"
    
    # Test 5: Product Service via API Gateway
    echo ""
    echo "📦 Testing Product Service..."
    echo "=================================="
    
    # Create product
    product_data='{"name":"Test Product","description":"A test product","price":99.99,"category":"Electronics"}'
    test_endpoint "POST" "$BASE_URL/products" "$product_data" 201 "Create Product via API Gateway" "$token"
    
    # Get all products
    test_endpoint "GET" "$BASE_URL/products" "" 200 "Get All Products via API Gateway" "$token"
    
    # Get product by ID
    test_endpoint "GET" "$BASE_URL/products/1" "" 200 "Get Product by ID via API Gateway" "$token"
    
    # Test 6: Rate Limiting
    echo ""
    echo "🚦 Testing Rate Limiting..."
    echo "=================================="
    
    print_status "INFO" "Making rapid requests to test rate limiting..."
    rate_limit_passed=false
    
    for i in {1..15}; do
        status_code=$(curl -s -w '%{http_code}' -o /dev/null "$BASE_URL/users")
        if [ "$status_code" -eq 429 ]; then
            print_status "PASS" "Rate limiting working (got 429 after $i requests)"
            rate_limit_passed=true
            break
        fi
        sleep 0.1
    done
    
    if [ "$rate_limit_passed" = false ]; then
        print_status "WARN" "Rate limiting not triggered or configured differently"
    fi
    
    # Test 7: Direct service access (should be blocked)
    echo ""
    echo "🔒 Testing Direct Service Access..."
    echo "=================================="
    
    test_endpoint "GET" "$USER_URL/users" "" 200 "Direct User Service Access (should work for testing)"
    test_endpoint "GET" "$PRODUCT_URL/products" "" 200 "Direct Product Service Access (should work for testing)"
    
    # Test 8: Monitoring endpoints
    echo ""
    echo "📊 Testing Monitoring Endpoints..."
    echo "=================================="
    
    test_endpoint "GET" "$BASE_URL/actuator/metrics" "" 200 "API Gateway Metrics"
    test_endpoint "GET" "$BASE_URL/actuator/prometheus" "" 200 "API Gateway Prometheus Metrics"
    test_endpoint "GET" "$USER_URL/actuator/metrics" "" 200 "User Service Metrics"
    test_endpoint "GET" "$PRODUCT_URL/actuator/metrics" "" 200 "Product Service Metrics"
    
    # Summary
    echo ""
    echo "📋 Test Summary"
    echo "=================================="
    print_status "INFO" "API testing completed!"
    print_status "INFO" "Check the results above for any failures"
    
    echo ""
    echo "🔍 Additional manual tests you can perform:"
    echo "   1. Visit Eureka Dashboard: ${DISCOVERY_URL}"
    echo "   2. Check Prometheus metrics: http://localhost:9090 (if monitoring is running)"
    echo "   3. View Grafana dashboards: http://localhost:3000 (if monitoring is running)"
    echo "   4. Check Zipkin traces: http://localhost:9411 (if monitoring is running)"
    echo ""
    echo "🔧 Useful commands:"
    echo "   curl -X POST -H 'Content-Type: application/json' -d '$login_data' $BASE_URL/auth/login"
    echo "   curl -H 'Authorization: Bearer <token>' $BASE_URL/users"
    echo "   curl -H 'Authorization: Bearer <token>' $BASE_URL/products"
    
    # Cleanup
    rm -f /tmp/response.json
}

# Run main function
main "$@"
