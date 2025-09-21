#!/bin/bash

# Microservices Startup Script - Updated for Dynamic Ports

echo "🚀 Starting Microservices with Dynamic Port Configuration..."

# Function to check if a fixed port is in use (only for discovery and gateway)
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is already in use"
        return 1
    else
        return 0
    fi
}

# Function to start a service with fixed port
start_service_fixed_port() {
    local service_name=$1
    local port=$2
    local directory=$3
    
    echo "📦 Starting $service_name on fixed port $port..."
    
    if check_port $port; then
        cd "$directory"
        
        # Create pids directory if it doesn't exist
        mkdir -p "$BASE_DIR/pids"
        
        # Start service in background
        nohup mvn spring-boot:run > "$BASE_DIR/logs/${service_name}.log" 2>&1 &
        local pid=$!
        echo $pid > "$BASE_DIR/pids/${service_name}.pid"
        
        echo "✅ $service_name started with PID $pid"
        sleep 2
    else
        echo "❌ Cannot start $service_name - port $port is in use"
    fi
}

# Function to start a service with dynamic port
start_service_dynamic_port() {
    local service_name=$1
    local directory=$2
    
    echo "📦 Starting $service_name with dynamic port (will be assigned by OS)..."
    
    cd "$directory"
    
    # Create pids directory if it doesn't exist
    mkdir -p "$BASE_DIR/pids"
    
    # Start service in background
    nohup mvn spring-boot:run > "$BASE_DIR/logs/${service_name}.log" 2>&1 &
    local pid=$!
    echo $pid > "$BASE_DIR/pids/${service_name}.pid"
    
    echo "✅ $service_name started with PID $pid (port will be discovered via Eureka)"
    sleep 2
}

# Create logs and pids directories
mkdir -p logs pids

# Base directory
BASE_DIR="/opt/projects/MicroservicesApiGateway"

echo "🔍 Checking prerequisites..."

# Check if Java and Maven are available
if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed"
    exit 1
fi

if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

echo "🎯 Starting services in dependency order..."
echo ""

# 1. Discovery Server (must start first - fixed port for service registration)
start_service_fixed_port "discovery-server" 8761 "$BASE_DIR/discovery-server"
sleep 10  # Give discovery server time to start

# 2. API Gateway (fixed port for external access)
start_service_fixed_port "api-gateway" 8080 "$BASE_DIR/api-gateway"
sleep 5

# 3. Auth Service (dynamic port - discovered via Eureka)
start_service_dynamic_port "auth-service" "$BASE_DIR/auth-service"
sleep 5

# 4. User Service (dynamic port - discovered via Eureka)
start_service_dynamic_port "user-service" "$BASE_DIR/user-service"
sleep 5

# 5. Product Service (dynamic port - discovered via Eureka)
start_service_dynamic_port "product-service" "$BASE_DIR/product-service"
sleep 5

echo ""
echo "⏳ Waiting for all services to register with Eureka..."
sleep 20

echo ""
echo "🔍 Checking service health via API Gateway..."

# Check fixed port services directly
gateway_health="http://localhost:8080/actuator/health"
if curl -s -f "$gateway_health" > /dev/null 2>&1; then
    echo "✅ API Gateway is healthy"
else
    echo "⚠️  API Gateway may not be ready yet"
fi

discovery_health="http://localhost:8761/actuator/health"
if curl -s -f "$discovery_health" > /dev/null 2>&1; then
    echo "✅ Discovery Server is healthy"
else
    echo "⚠️  Discovery Server may not be ready yet"
fi

# Check dynamic port services via API Gateway
services_via_gateway=(
    "auth-service"
    "user-service" 
    "product-service"
)

for service in "${services_via_gateway[@]}"; do
    health_url="http://localhost:8080/$service/actuator/health"
    if curl -s -f "$health_url" > /dev/null 2>&1; then
        echo "✅ $service is healthy (via Gateway)"
    else
        echo "⚠️  $service may not be ready yet (check Eureka registration)"
    fi
done

echo ""
echo "🎉 Microservices startup complete!"
echo ""
echo "🌐 Service URLs:"
echo "   Discovery Server:    http://localhost:8761 (View registered services)"
echo "   API Gateway:         http://localhost:8080 (Entry point for all requests)"
echo "   Auth Service:        http://localhost:8080/auth-service (via Gateway)"
echo "   User Service:        http://localhost:8080/user-service (via Gateway)"
echo "   Product Service:     http://localhost:8080/product-service (via Gateway)"
echo ""
echo "📊 Monitoring URLs (if monitoring stack is running):"
echo "   Prometheus:          http://localhost:9090"
echo "   Grafana:             http://localhost:3000"
echo "   Zipkin:              http://localhost:9411"
echo ""
echo "📋 Service management:"
echo "   View logs:           tail -f logs/<service-name>.log"
echo "   Stop service:        kill \$(cat pids/<service-name>.pid)"
echo "   Stop all:            ./stop-services.sh"
echo "   Service manager:     ./service-manager.sh status all"
echo "   Test APIs:           ./test-apis.sh"
echo ""
echo "ℹ️  Note: Services with dynamic ports are accessed through the API Gateway."
echo "   Use the Discovery Server dashboard to see actual assigned ports."
