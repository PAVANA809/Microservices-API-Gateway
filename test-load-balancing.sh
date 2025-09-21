#!/bin/bash

# Load Balancing Test Script for Microservices API Gateway
# Tests how the API Gateway distributes load across multiple service instances

# Configuration
API_HOST=${API_HOST:-"localhost"}
GATEWAY_PORT=${GATEWAY_PORT:-"8080"}
BASE_URL="http://${API_HOST}:${GATEWAY_PORT}"
DISCOVERY_URL="http://${API_HOST}:8761"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
        "TEST")
            echo -e "${PURPLE}🧪 TEST${NC}: $message"
            ;;
        "RESULT")
            echo -e "${CYAN}📊 RESULT${NC}: $message"
            ;;
    esac
}

# Function to get authentication token
get_auth_token() {
    print_status "INFO" "Obtaining authentication token..." >&2
    
    # Try to login (assuming default credentials exist)
    login_data='{"username":"admin","password":"admin123"}'
    
    # Try different login endpoints
    login_endpoints=(
        "$BASE_URL/auth-service/api/auth/login"
    )
    
    for endpoint in "${login_endpoints[@]}"; do
        token_response=$(curl -s -X POST -H "Content-Type: application/json" -d "$login_data" "$endpoint" 2>/dev/null)
        
        if command -v jq &> /dev/null; then
            token=$(echo "$token_response" | jq -r '.token // .accessToken // .access_token // empty' 2>/dev/null)
        else
            token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
            if [ -z "$token" ]; then
                token=$(echo "$token_response" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
            fi
        fi
        
        if [ ! -z "$token" ] && [ "$token" != "null" ]; then
            print_status "PASS" "Authentication token obtained" >&2
            echo "$token"
            return 0
        fi
    done
    
    print_status "WARN" "Could not obtain authentication token, proceeding without auth" >&2
    echo ""
    return 1
}

# Function to start multiple instances of a service
start_multiple_instances() {
    local service_name=$1
    local instance_count=$2
    local service_dir="$service_name"
    
    print_status "INFO" "Starting $instance_count instances of $service_name"
    
    # Create directories for multiple instances
    mkdir -p "pids/multi-instance"
    mkdir -p "logs/multi-instance"
    
    for i in $(seq 1 $instance_count); do
        instance_name="${service_name}-instance-${i}"
        
        print_status "INFO" "Starting $instance_name..."
        
        cd "$service_dir"
        
        # Start service instance with different server port
        SPRING_PROFILES_ACTIVE="multi-instance-${i}" \
        SERVER_PORT=0 \
        EUREKA_INSTANCE_INSTANCE_ID="${service_name}-${i}" \
        nohup mvn spring-boot:run \
            -Dspring-boot.run.jvmArguments="-Dserver.port=0 -Deureka.instance.instance-id=${service_name}-${i}" \
            > "../logs/multi-instance/${instance_name}.log" 2>&1 &
        
        local pid=$!
        echo $pid > "../pids/multi-instance/${instance_name}.pid"
        
        print_status "INFO" "$instance_name started with PID $pid"
        cd ..
        
        # Wait a bit between starts
        sleep 3
    done
    
    print_status "INFO" "Waiting for all $service_name instances to register with Eureka..."
    sleep 15
}

# Function to stop multiple instances
stop_multiple_instances() {
    local service_name=$1
    
    print_status "INFO" "Stopping all instances of $service_name"
    
    # Stop all instances
    for pid_file in pids/multi-instance/${service_name}-instance-*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            local instance_name=$(basename "$pid_file" .pid)
            
            if kill -0 "$pid" 2>/dev/null; then
                print_status "INFO" "Stopping $instance_name (PID: $pid)"
                kill "$pid"
                
                # Wait for graceful shutdown
                for i in {1..10}; do
                    if ! kill -0 "$pid" 2>/dev/null; then
                        break
                    fi
                    sleep 1
                done
                
                # Force kill if still running
                if kill -0 "$pid" 2>/dev/null; then
                    kill -9 "$pid"
                fi
            fi
            
            rm -f "$pid_file"
        fi
    done
}

# Function to check Eureka registry
check_eureka_instances() {
    local service_name=$1
    
    print_status "INFO" "Checking $service_name instances in Eureka registry..."
    
    # Get service instances from Eureka
    eureka_response=$(curl -s "$DISCOVERY_URL/eureka/apps/$service_name" -H "Accept: application/json" 2>/dev/null)
    
    if command -v jq &> /dev/null && [ ! -z "$eureka_response" ]; then
        instance_count=$(echo "$eureka_response" | jq -r '.application.instance | length' 2>/dev/null)
        
        if [ "$instance_count" != "null" ] && [ "$instance_count" -gt 0 ]; then
            print_status "PASS" "$instance_count instances of $service_name found in Eureka"
            
            # Show instance details
            echo "$eureka_response" | jq -r '.application.instance[] | "  - Instance ID: \(.instanceId), Host: \(.hostName), Port: \(.port."$")"' 2>/dev/null
            return $instance_count
        fi
    fi
    
    print_status "WARN" "Could not retrieve instance information from Eureka"
    return 0
}

# Function to test load distribution
test_load_distribution() {
    local service_endpoint=$1
    local request_count=$2
    local auth_token=$3
    
    print_status "TEST" "Testing load distribution across instances"
    print_status "INFO" "Making $request_count requests to $service_endpoint"
    
    # Array to store response times and instance information
    declare -A instance_hits
    declare -a response_times
    local successful_requests=0
    local failed_requests=0
    
    echo "Request | Status | Response Time | Instance Info"
    echo "--------|--------|---------------|---------------"
    
    for i in $(seq 1 $request_count); do
        local start_time=$(date +%s%3N)
        
        # Create a temporary file to capture headers and body separately
        local temp_headers=$(mktemp)
        local temp_body=$(mktemp)
        
        if [ ! -z "$auth_token" ]; then
            # Use separate curl call to get clean status code
            local status_code=$(curl -s -o "$temp_body" -D "$temp_headers" -w '%{http_code}' \
                -H "Authorization: Bearer $auth_token" \
                -H "X-Request-ID: load-test-$i" \
                "$service_endpoint" 2>/dev/null)
            local curl_time=$(curl -s -o /dev/null -w '%{time_total}' \
                -H "Authorization: Bearer $auth_token" \
                -H "X-Request-ID: load-test-$i" \
                "$service_endpoint" 2>/dev/null)
        else
            local status_code=$(curl -s -o "$temp_body" -D "$temp_headers" -w '%{http_code}' \
                -H "X-Request-ID: load-test-$i" \
                "$service_endpoint" 2>/dev/null)
            local curl_time=$(curl -s -o /dev/null -w '%{time_total}' \
                -H "X-Request-ID: load-test-$i" \
                "$service_endpoint" 2>/dev/null)
        fi
        
        local end_time=$(date +%s%3N)
        local total_time=$((end_time - start_time))
        
        # Read the response body
        local body=""
        if [ -f "$temp_body" ]; then
            body=$(cat "$temp_body" 2>/dev/null || echo "")
        fi
        
        # Extract instance information from various sources
        local instance_info="Unknown"
        
        # Method 1: Try to get from response headers
        if [ -f "$temp_headers" ]; then
            # Look for common instance identification headers
            instance_info=$(grep -i "x-instance-id:\|x-server-id:\|server:" "$temp_headers" | head -1 | cut -d':' -f2- | tr -d ' \r\n' 2>/dev/null || echo "")
        fi
        
        # Method 2: If no instance info from headers, try to parse port from loadTest endpoint response
        if [ -z "$instance_info" ] || [ "$instance_info" = "" ]; then
            if [ ! -z "$body" ]; then
                # Look for "PORT: xxxx" pattern in response body
                local port_match=$(echo "$body" | grep -o 'PORT: [0-9]*' | head -1)
                if [ ! -z "$port_match" ]; then
                    instance_info=$(echo "$port_match" | sed 's/PORT: /Port-/')
                fi
            fi
        fi
        
        # Method 3: If still no port info, try to parse from JSON health response
        if [ -z "$instance_info" ] || [ "$instance_info" = "" ]; then
            if command -v jq &> /dev/null && [ ! -z "$body" ]; then
                # For health check responses, try to extract useful info
                local json_instance=$(echo "$body" | jq -r '.components.diskSpace.details.path // .status // empty' 2>/dev/null || echo "")
                if [ ! -z "$json_instance" ] && [ "$json_instance" != "null" ]; then
                    # Extract a unique identifier from the path or other components
                    local path_hash=$(echo "$json_instance" | md5sum 2>/dev/null | cut -c1-8 || echo "")
                    if [ ! -z "$path_hash" ]; then
                        instance_info="Service-$path_hash"
                    fi
                fi
            fi
        fi
        
        # Method 4: Use a combination of response timing and content hash as more stable identifier
        if [ -z "$instance_info" ] || [ "$instance_info" = "Unknown" ] || [ "$instance_info" = "" ]; then
            # Create a more stable identifier using response time pattern and body hash
            local timing_bucket=$(printf "%.0f" "$(echo "$curl_time * 1000" | bc 2>/dev/null || echo "0")")
            local timing_group=$((timing_bucket / 5))  # Group by 5ms intervals
            local body_hash=""
            if [ ! -z "$body" ]; then
                body_hash=$(echo "$body" | md5sum 2>/dev/null | cut -c1-4 || echo "")
            fi
            instance_info="Server-${timing_group}${body_hash}"
        fi
        
        # Clean up temporary files
        rm -f "$temp_headers" "$temp_body"
        
        # Ensure status_code is numeric
        if ! [[ "$status_code" =~ ^[0-9]+$ ]]; then
            status_code="000"
        fi
        
        if [ "$status_code" -eq 200 ]; then
            successful_requests=$((successful_requests + 1))
            instance_hits["$instance_info"]=$((${instance_hits["$instance_info"]:-0} + 1))
            response_times+=("$curl_time")
        else
            failed_requests=$((failed_requests + 1))
            # Track failed requests with their instance info
            local failed_key="${instance_info}-FAILED"
            instance_hits["$failed_key"]=$((${instance_hits["$failed_key"]:-0} + 1))
        fi
        
        printf "%7d | %6s | %13s | %s\n" "$i" "$status_code" "${curl_time}s" "$instance_info"
        
        # Small delay between requests to see load balancing
        sleep 1
    done
    
    echo ""
    print_status "RESULT" "Load Distribution Summary"
    echo "=========================="
    printf "Total Requests: %d\n" "$request_count"
    printf "Successful: %d\n" "$successful_requests"
    printf "Failed: %d\n" "$failed_requests"
    printf "Success Rate: %.2f%%\n" "$(echo "scale=2; $successful_requests * 100 / $request_count" | bc 2>/dev/null || echo "N/A")"
    echo ""
    
    if [ ${#instance_hits[@]} -gt 0 ]; then
        print_status "RESULT" "Requests per Instance:"
        local total_hits=0
        for instance in "${!instance_hits[@]}"; do
            local hits=${instance_hits[$instance]}
            total_hits=$((total_hits + hits))
            printf "  %-20s: %3d requests (%.1f%%)\n" "$instance" "$hits" "$(echo "scale=1; $hits * 100 / $successful_requests" | bc 2>/dev/null || echo "N/A")"
        done
        
        # Calculate load balancing effectiveness
        local unique_instances=${#instance_hits[@]}
        if [ $unique_instances -gt 1 ]; then
            print_status "PASS" "Load balancing is working - requests distributed across $unique_instances instances"
            
            # Check if distribution is reasonably balanced
            local expected_per_instance=$((successful_requests / unique_instances))
            local balanced=true
            
            for hits in "${instance_hits[@]}"; do
                local variance=$((hits - expected_per_instance))
                local variance_abs=${variance#-}  # absolute value
                local threshold=$((expected_per_instance / 3))  # 33% threshold
                
                if [ $variance_abs -gt $threshold ]; then
                    balanced=false
                    break
                fi
            done
            
            if [ "$balanced" = true ]; then
                print_status "PASS" "Load distribution appears well-balanced"
            else
                print_status "WARN" "Load distribution may be uneven - check load balancing algorithm"
            fi
        else
            print_status "FAIL" "Load balancing not working - all requests went to single instance"
        fi
    else
        print_status "FAIL" "Could not determine instance distribution"
    fi
    
    # Response time statistics
    if [ ${#response_times[@]} -gt 0 ]; then
        echo ""
        print_status "RESULT" "Response Time Statistics:"
        
        # Calculate min, max, average
        local min_time=${response_times[0]}
        local max_time=${response_times[0]}
        local total_time=0
        
        for time in "${response_times[@]}"; do
            total_time=$(echo "$total_time + $time" | bc 2>/dev/null || echo "$total_time")
            if (( $(echo "$time < $min_time" | bc 2>/dev/null || echo 0) )); then
                min_time=$time
            fi
            if (( $(echo "$time > $max_time" | bc 2>/dev/null || echo 0) )); then
                max_time=$time
            fi
        done
        
        local avg_time=$(echo "scale=3; $total_time / ${#response_times[@]}" | bc 2>/dev/null || echo "N/A")
        
        printf "  Min Response Time: %s seconds\n" "$min_time"
        printf "  Max Response Time: %s seconds\n" "$max_time"
        printf "  Avg Response Time: %s seconds\n" "$avg_time"
    fi
}

# Function to test concurrent load
test_concurrent_load() {
    local service_endpoint=$1
    local concurrent_users=$2
    local requests_per_user=$3
    local auth_token=$4
    
    print_status "TEST" "Testing concurrent load with $concurrent_users users making $requests_per_user requests each"
    
    # Create temporary directory for concurrent test results
    mkdir -p "/tmp/load_test_$$"
    
    # Start concurrent users
    local pids=()
    for user in $(seq 1 $concurrent_users); do
        (
            for req in $(seq 1 $requests_per_user); do
                local start_time=$(date +%s%3N)
                
                if [ ! -z "$auth_token" ]; then
                    response=$(curl -s -w '%{http_code}' \
                        -H "Authorization: Bearer $auth_token" \
                        -H "X-User-ID: user-$user" \
                        -H "X-Request-ID: concurrent-$user-$req" \
                        "$service_endpoint" 2>/dev/null)
                else
                    response=$(curl -s -w '%{http_code}' \
                        -H "X-User-ID: user-$user" \
                        -H "X-Request-ID: concurrent-$user-$req" \
                        "$service_endpoint" 2>/dev/null)
                fi
                
                local end_time=$(date +%s%3N)
                local duration=$((end_time - start_time))
                
                echo "$user,$req,$(echo "$response" | tail -c 4),$duration" >> "/tmp/load_test_$$/user_$user.log"
                
                sleep 0.05  # Small delay between requests
            done
        ) &
        pids+=($!)
    done
    
    print_status "INFO" "Waiting for all concurrent users to complete..."
    
    # Wait for all background processes to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    print_status "RESULT" "Concurrent Load Test Results:"
    echo "============================="
    
    # Analyze results
    local total_requests=0
    local successful_requests=0
    local total_response_time=0
    
    for user in $(seq 1 $concurrent_users); do
        if [ -f "/tmp/load_test_$$/user_$user.log" ]; then
            local user_requests=$(wc -l < "/tmp/load_test_$$/user_$user.log")
            local user_success=$(grep ",200," "/tmp/load_test_$$/user_$user.log" | wc -l)
            
            total_requests=$((total_requests + user_requests))
            successful_requests=$((successful_requests + user_success))
            
            # Sum response times for this user
            while IFS=',' read -r user_id req_id status_code response_time; do
                total_response_time=$((total_response_time + response_time))
            done < "/tmp/load_test_$$/user_$user.log"
            
            printf "User %2d: %d requests, %d successful (%.1f%%)\n" \
                "$user" "$user_requests" "$user_success" \
                "$(echo "scale=1; $user_success * 100 / $user_requests" | bc 2>/dev/null || echo "N/A")"
        fi
    done
    
    echo ""
    printf "Total Requests: %d\n" "$total_requests"
    printf "Successful: %d\n" "$successful_requests"
    printf "Failed: %d\n" "$((total_requests - successful_requests))"
    printf "Overall Success Rate: %.2f%%\n" "$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc 2>/dev/null || echo "N/A")"
    printf "Average Response Time: %.0f ms\n" "$(echo "scale=0; $total_response_time / $total_requests" | bc 2>/dev/null || echo "N/A")"
    
    # Cleanup
    rm -rf "/tmp/load_test_$$"
}

# Main test execution
main() {
    echo "🚀 Load Balancing Test for Microservices API Gateway"
    echo "===================================================="
    echo ""
    
    print_status "INFO" "Configuration:"
    echo "  Gateway URL: $BASE_URL"
    echo "  Discovery URL: $DISCOVERY_URL"
    echo ""
    
    # Check if services are running
    print_status "INFO" "Checking if API Gateway is accessible..."
    if ! curl -s -f "$BASE_URL/actuator/health" >/dev/null 2>&1; then
        print_status "FAIL" "API Gateway is not accessible. Please start services first."
        echo "Run: ./start-services.sh"
        exit 1
    fi
    
    print_status "PASS" "API Gateway is accessible"
    
    # Get authentication token
    auth_token=$(get_auth_token) 
    echo "Auth Token: $auth_token"
    # Test selection
    echo ""
    echo "Select load balancing test:"
    echo "1. Test with multiple User Service instances"
    echo "2. Test with multiple Product Service instances"
    echo "3. Concurrent load test"
    echo "4. Full comprehensive test"
    echo "5. Skip service startup and test existing instances"
    echo ""
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            print_status "INFO" "Testing User Service load balancing"
            start_multiple_instances "user-service" 3
            check_eureka_instances "USER-SERVICE"
            test_load_distribution "$BASE_URL/user-service/api/users/loadtest" 20 "$auth_token"
            stop_multiple_instances "user-service"
            ;;
        2)
            print_status "INFO" "Testing Product Service load balancing"
            start_multiple_instances "product-service" 3
            check_eureka_instances "PRODUCT-SERVICE"
            test_load_distribution "$BASE_URL/product-service/api/products/loadtest" 20 "$auth_token"
            stop_multiple_instances "product-service"
            ;;
        3)
            print_status "INFO" "Running concurrent load test"
            test_concurrent_load "$BASE_URL/user-service/api/users/loadtest" 5 10 "$auth_token"
            ;;
        4)
            print_status "INFO" "Running comprehensive load balancing test"
            
            # Test User Service
            echo ""
            print_status "TEST" "Phase 1: User Service Load Balancing"
            start_multiple_instances "user-service" 3
            sleep 10
            check_eureka_instances "USER-SERVICE"
            test_load_distribution "$BASE_URL/user-service/api/users/loadtest" 30 "$auth_token"
            
            # Concurrent test
            echo ""
            print_status "TEST" "Phase 2: Concurrent Load Test"
            test_concurrent_load "$BASE_URL/user-service/api/users/loadtest" 5 10 "$auth_token"
            
            stop_multiple_instances "user-service"
            ;;
        5)
            print_status "INFO" "Testing existing service instances"
            check_eureka_instances "USER-SERVICE"
            test_load_distribution "$BASE_URL/user-service/api/users/loadtest" 20 "$auth_token"
            ;;
        *)
            print_status "FAIL" "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    print_status "INFO" "Load balancing test completed!"
    echo ""
    print_status "INFO" "Additional Notes:"
    echo "- Check Eureka Dashboard: $DISCOVERY_URL"
    echo "- Monitor service logs in logs/multi-instance/ directory"
    echo "- For production, consider implementing custom load balancing algorithms"
    echo "- Monitor response times and error rates in production"
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    print_status "FAIL" "curl is required but not installed"
    exit 1
fi

if ! command -v bc &> /dev/null; then
    print_status "WARN" "bc (calculator) not found - some statistics may not be available"
fi

# Run main function
main "$@"
