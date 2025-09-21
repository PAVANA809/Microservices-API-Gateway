#!/bin/bash

# Microservices API Testing Script - Updated for Dynamic Ports

# Dynamic Base URLs using environment variables with fallback to localhost
API_HOST=${API_HOST:-"localhost"}
DISCOVERY_HOST=${DISCOVERY_HOST:-"localhost"}

# Port configurations - Only Gateway and Discovery use fixed ports
GATEWAY_PORT=${GATEWAY_PORT:-"8080"}
DISCOVERY_PORT=${DISCOVERY_PORT:-"8761"}

# Construct URLs - All services accessed through API Gateway except Discovery
BASE_URL="http://${API_HOST}:${GATEWAY_PORT}"
DISCOVERY_URL="http://${DISCOVERY_HOST}:${DISCOVERY_PORT}"

# Service endpoints via API Gateway
AUTH_SERVICE_URL="$BASE_URL/auth-service"
USER_SERVICE_URL="$BASE_URL/user-service"
PRODUCT_SERVICE_URL="$BASE_URL/product-service"

echo "🧪 Testing Microservices API..."
echo ""
echo "🌐 Configuration:"
echo "   API Host: ${API_HOST}"
echo "   Gateway URL: ${BASE_URL}"
echo "   Auth Service URL (via Gateway): ${AUTH_SERVICE_URL}"
echo "   User Service URL (via Gateway): ${USER_SERVICE_URL}"
echo "   Product Service URL (via Gateway): ${PRODUCT_SERVICE_URL}"
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

# Function to discover available authentication endpoints
discover_auth_endpoints() {
    print_status "INFO" "Discovering available authentication endpoints..."
    
    # Check common auth endpoints via Gateway
    auth_endpoints=(
        "/auth-service/api/auth/register"
        "/auth-service/api/auth/login" 
        "/auth-service/api/auth/validate"
        "/auth-service/api/register"
        "/auth-service/api/login"
        "/auth-service/api/validate"
    )
    
    for endpoint in "${auth_endpoints[@]}"; do
        gateway_status=$(curl -s -w '%{http_code}' -o /dev/null "$BASE_URL$endpoint" 2>/dev/null)
        
        if [ "$gateway_status" -ne 404 ]; then
            print_status "INFO" "Found endpoint: $endpoint (Status: $gateway_status)"
        fi
    done
}

# Function to create default test user if needed
create_test_user() {
    print_status "INFO" "Creating default test user for testing..."
    
    # Try registration endpoints via API Gateway
    registration_endpoints=(
        "$AUTH_SERVICE_URL/api/auth/register"
        "$AUTH_SERVICE_URL/api/register"
    )
    
    test_user='{"username":"apitest","password":"Test123!","email":"apitest@example.com","firstName":"API","lastName":"Test"}'
    
    for reg_endpoint in "${registration_endpoints[@]}"; do
        response=$(curl -s -w '%{http_code}' -X POST -H "Content-Type: application/json" -d "$test_user" "$reg_endpoint" -o /tmp/reg_response.json)
        status=$(echo "$response" | tail -c 4)
        
        if [ "$status" -eq 200 ] || [ "$status" -eq 201 ]; then
            print_status "PASS" "Test user created successfully at $reg_endpoint"
            return 0
        elif [ "$status" -eq 409 ]; then
            print_status "INFO" "Test user already exists"
            return 0
        fi
    done
    
    print_status "WARN" "Could not create test user at any endpoint"
    return 1
}

# Function to test endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local expected_status=$4
    local description=$5
    local auth_token=$6
    
    echo ""
    print_status "INFO" "Testing: $description"
    echo "   Method: $method"
    echo "   URL: $url"
    
    if [ ! -z "$data" ]; then
        echo "   Data: $data"
    fi
    
    if [ ! -z "$auth_token" ]; then
        echo "   Using Authentication: Bearer ${auth_token:0:20}..."
    fi
    
    # Execute request with proper token handling
    local status_code
    if [ ! -z "$auth_token" ]; then
        if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
            status_code=$(curl -s -w '%{http_code}' -o /tmp/response.json \
                -H "Authorization: Bearer $auth_token" \
                -H "Content-Type: application/json" \
                -d "$data" \
                -X "$method" "$url")
        else
            status_code=$(curl -s -w '%{http_code}' -o /tmp/response.json \
                -H "Authorization: Bearer $auth_token" \
                -X "$method" "$url")
        fi
    else
        if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
            status_code=$(curl -s -w '%{http_code}' -o /tmp/response.json \
                -H "Content-Type: application/json" \
                -d "$data" \
                -X "$method" "$url")
        else
            status_code=$(curl -s -w '%{http_code}' -o /tmp/response.json \
                -X "$method" "$url")
        fi
    fi
    
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
    
    # Service URLs for health checks - only check Gateway and Discovery directly
    services=(
        "${DISCOVERY_URL}/actuator/health|Discovery Server|200"
        "${BASE_URL}/actuator/health|API Gateway|200"
        "${AUTH_SERVICE_URL}/actuator/health|Auth Service (via Gateway)|200"
        "${USER_SERVICE_URL}/actuator/health|User Service (via Gateway)|200"
        "${PRODUCT_SERVICE_URL}/actuator/health|Product Service (via Gateway)|200"
    )
    
    for service in "${services[@]}"; do
        IFS='|' read -r url name expected_status <<< "$service"
        # Trim whitespace from expected_status
        expected_status="$(echo "$expected_status" | xargs)"
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
    test_endpoint "GET" "$AUTH_SERVICE_URL/actuator/health" "" 200 "Auth Service Health Check (via Gateway)"
    
    # Test 2: Service Discovery
    test_endpoint "GET" "$DISCOVERY_URL" "" 200 "Eureka Dashboard"
    
    # Test 3: Authentication
    echo ""
    echo "🔐 Testing Authentication..."
    echo "=================================="

    # First, check if we can register a test user or if default users exist
    print_status "INFO" "Checking authentication endpoints..."

    # Try to register a test user first
    register_data='{"username":"testuser","password":"testpass123","email":"testuser@example.com","firstName":"Test","lastName":"User"}'

    print_status "INFO" "Attempting to register test user..."
    
    # Try registration endpoints via API Gateway
    registration_endpoints=(
        "$AUTH_SERVICE_URL/api/auth/signup"
        "$AUTH_SERVICE_URL/api/auth/register"
    )
    
    registration_success=false
    for reg_endpoint in "${registration_endpoints[@]}"; do
        register_response=$(curl -s -w '%{http_code}' -X POST -H "Content-Type: application/json" -d "$register_data" "$reg_endpoint" -o /tmp/register_response.json)
        register_status=$(echo "$register_response" | tail -c 4)
        register_body=$(cat /tmp/register_response.json 2>/dev/null || echo "")

        if [ "$register_status" -eq 201 ] || [ "$register_status" -eq 200 ]; then
            print_status "PASS" "Test user registered successfully at $reg_endpoint"
            login_data='{"username":"testuser","password":"testpass123"}'
            registration_success=true
            break
        elif [ "$register_status" -eq 409 ] || [[ "$register_body" == *"already"* ]]; then
            print_status "INFO" "Test user already exists, using existing credentials"
            login_data='{"username":"testuser","password":"testpass123"}'
            registration_success=true
            break
        else
            print_status "WARN" "Registration failed at $reg_endpoint (Status: $register_status)"
        fi
    done

    if [ "$registration_success" = false ]; then
        print_status "WARN" "Could not register test user. Trying default credentials..."
        
        # Try common default credentials with correct endpoints
        default_credentials=(
            '{"username":"admin","password":"admin"}'
            '{"username":"admin","password":"password"}'
            '{"username":"user","password":"password"}'
            '{"username":"test","password":"test"}'
        )
        
        login_data=""
        login_endpoints=(
            "$AUTH_SERVICE_URL/api/auth/login"
        )
        
        for cred in "${default_credentials[@]}"; do
            username=$(echo $cred | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
            print_status "INFO" "Trying credentials: $username"
            
            for login_endpoint in "${login_endpoints[@]}"; do
                test_response=$(curl -s -w '%{http_code}' -X POST -H "Content-Type: application/json" -d "$cred" "$login_endpoint" -o /tmp/login_test.json)
                test_status=$(echo "$test_response" | tail -c 4)
                
                if [ "$test_status" -eq 200 ]; then
                    print_status "PASS" "Found working credentials: $username at $login_endpoint"
                    login_data="$cred"
                    break 2
                fi
            done
        done
        
        if [ -z "$login_data" ]; then
            print_status "FAIL" "No working credentials found. Creating default admin user..."
            # Try to create admin user via Gateway
            admin_data='{"username":"admin","email":"admin@example.com","password":"admin123"}'
            
            for reg_endpoint in "${registration_endpoints[@]}"; do
                curl -s -X POST -H "Content-Type: application/json" -d "$admin_data" "$reg_endpoint" > /dev/null 2>&1
            done
            
            login_data='{"username":"admin","password":"admin123"}'
        fi
    fi

    # Now attempt login with determined credentials
    print_status "INFO" "Attempting login with determined credentials..."
    echo "Login data: $login_data"

    # Try login via API Gateway
    login_endpoints=(
        "$AUTH_SERVICE_URL/api/auth/login"
    )
    
    token=""
    for login_endpoint in "${login_endpoints[@]}"; do
        print_status "INFO" "Trying login at: $login_endpoint"
        token_response=$(curl -s -X POST -H "Content-Type: application/json" -d "$login_data" "$login_endpoint")
        echo "Login response from $login_endpoint: $token_response"

        # Extract token with fallback methods
        if command -v jq &> /dev/null; then
            token=$(echo "$token_response" | jq -r '.token // .accessToken // .access_token // empty' 2>/dev/null)
        else
            # Fallback: simple grep extraction
            token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
            if [ -z "$token" ]; then
                token=$(echo "$token_response" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
            fi
        fi

        if [ ! -z "$token" ] && [ "$token" != "null" ] && [ "$token" != "" ]; then
            print_status "PASS" "Authentication successful at $login_endpoint, token received"
            echo "Token (first 50 chars): ${token:0:50}..."
            break
        else
            print_status "WARN" "Could not extract token from $login_endpoint"
        fi
    done

    if [ -z "$token" ] || [ "$token" = "null" ]; then
        print_status "FAIL" "Authentication failed at all endpoints"
        print_status "INFO" "Last response was: $token_response"
        token=""
        print_status "WARN" "Continuing tests without authentication token..."
    fi

    # Validate token if we have one
    if [ ! -z "$token" ]; then
        print_status "INFO" "Validating token..."
        validate_endpoints=(
            "$AUTH_SERVICE_URL/api/auth/validate"
        )
        
        for validate_endpoint in "${validate_endpoints[@]}"; do
            validate_response=$(curl -s -w '%{http_code}' -H "Authorization: Bearer $token" "$validate_endpoint" -o /tmp/validate_response.json)
            validate_status=$(echo "$validate_response" | tail -c 4)
            
            if [ "$validate_status" -eq 200 ]; then
                print_status "PASS" "Token validation successful at $validate_endpoint"
                break
            fi
        done
    fi

    # Test 4: User Service via API Gateway
    echo ""
    echo "👥 Testing User Service..."
    echo "=================================="
    
    # Create user
    user_data='{"username":"testuser","email":"test@example.com","firstName":"Test","lastName":"User"}'
    test_endpoint "POST" "$USER_SERVICE_URL/api/users" "$user_data" 201 "Create User via API Gateway" "$token"
    
    # Get all users
    test_endpoint "GET" "$USER_SERVICE_URL/api/users" "" 200 "Get All Users via API Gateway" "$token"
    
    # Get user by ID
    test_endpoint "GET" "$BASE_URL/user-service/api/users/1" "" 200 "Get User by ID via API Gateway" "$token"
    
    # Test 5: Product Service via API Gateway
    echo ""
    echo "📦 Testing Product Service..."
    echo "=================================="
    
    # Test 5: Product Service via API Gateway
    echo ""
    echo "🛍️  Testing Product Service..."
    echo "=================================="
    
    # Create product
    product_data='{"name":"Test Product","description":"A test product","price":99.99,"category":"Electronics","sku":"TEST-PROD-001","stockQuantity":10}'
    test_endpoint "POST" "$PRODUCT_SERVICE_URL/api/products" "$product_data" 201 "Create Product via API Gateway" "$token"
    
    # Get all products
    test_endpoint "GET" "$PRODUCT_SERVICE_URL/api/products" "" 200 "Get All Products via API Gateway" "$token"
    
    # Get product by ID
    test_endpoint "GET" "$PRODUCT_SERVICE_URL/api/products/1" "" 200 "Get Product by ID via API Gateway" "$token"
    
    # Test 6: Rate Limiting
    echo ""
    echo "🚦 Testing Rate Limiting..."
    echo "=================================="
    
    print_status "INFO" "Making rapid requests to test rate limiting with authentication..."
    rate_limit_passed=false
    
    for i in {1..15}; do
        if [ ! -z "$token" ]; then
            status_code=$(curl -s -w '%{http_code}' -o /dev/null -H "Authorization: Bearer $token" "$USER_SERVICE_URL/api/users/health")
        else
            status_code=$(curl -s -w '%{http_code}' -o /dev/null "$USER_SERVICE_URL/api/users/health")
        fi
        
        echo "Request $i: HTTP $status_code"
        
        if [ "$status_code" -eq 429 ]; then
            print_status "PASS" "Rate limiting working (got 429 after $i requests)"
            rate_limit_passed=true
            break
        fi
        
        # Small delay to see rate limiting pattern
        sleep 0.1
    done
    
    if [ "$rate_limit_passed" = false ]; then
        print_status "WARN" "Rate limiting not triggered within 15 requests - check configuration"
    fi
    
    # Test 7: Service Discovery Verification
    echo ""
    echo "� Testing Service Discovery via Gateway..."
    echo "=================================="
    
    print_status "INFO" "All service calls are now routed through API Gateway"
    print_status "INFO" "Services are using dynamic ports and discovered via Eureka"
    test_endpoint "GET" "$AUTH_SERVICE_URL/api/auth/health" "" 200 "Auth Service Health via Gateway"
    test_endpoint "GET" "$USER_SERVICE_URL/api/users/health" "" 200 "User Service Health via Gateway" "$token"
    test_endpoint "GET" "$PRODUCT_SERVICE_URL/api/products/health" "" 200 "Product Service Health via Gateway" "$token"
    
    # Test 8: Monitoring endpoints
    echo ""
    echo "📊 Testing Monitoring Endpoints..."
    echo "=================================="
    
    test_endpoint "GET" "$BASE_URL/actuator/metrics" "" 200 "API Gateway Metrics"
    test_endpoint "GET" "$BASE_URL/actuator/prometheus" "" 200 "API Gateway Prometheus Metrics"
    
    # Summary
    echo ""
    echo "📋 Test Summary"
    echo "=================================="
    print_status "INFO" "API testing completed!"
    print_status "INFO" "All services are now using dynamic ports and accessed via API Gateway"
    print_status "INFO" "Check the results above for any failures"
    
    echo ""
    echo "🔍 Additional manual tests you can perform:"
    echo "   1. Visit Eureka Dashboard: ${DISCOVERY_URL}"
    echo "   2. Check Prometheus metrics: http://localhost:9090 (if monitoring is running)"
    echo "   3. View Grafana dashboards: http://localhost:3000 (if monitoring is running)"
    echo "   4. Check Zipkin traces: http://localhost:9411 (if monitoring is running)"
    echo ""
    echo "🔧 Useful commands:"
    echo "   curl -X POST -H 'Content-Type: application/json' -d '$login_data' $AUTH_SERVICE_URL/api/auth/login"
    echo "   curl -H 'Authorization: Bearer <token>' $USER_SERVICE_URL/api/users"
    echo "   curl -H 'Authorization: Bearer <token>' $PRODUCT_SERVICE_URL/api/products"
    
    # Cleanup
    rm -f /tmp/response.json
}

# Run main function
main "$@"
