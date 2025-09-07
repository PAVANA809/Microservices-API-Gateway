#!/bin/bash

# Microservices Startup Script

echo "🚀 Starting Microservices..."

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is already in use"
        return 1
    else
        return 0
    fi
}

# Function to start a service
start_service() {
    local service_name=$1
    local port=$2
    local directory=$3
    
    echo "📦 Starting $service_name on port $port..."
    
    if check_port $port; then
        cd "$directory"
        
        # Start service in background
        nohup mvn spring-boot:run > "../logs/${service_name}.log" 2>&1 &
        local pid=$!
        echo $pid > "../logs/${service_name}.pid"
        
        echo "✅ $service_name started with PID $pid"
        sleep 2
    else
        echo "❌ Cannot start $service_name - port $port is in use"
    fi
}

# Create logs directory
mkdir -p logs

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

# Start services in order
echo "🎯 Starting services in dependency order..."
echo ""

# 1. Discovery Server (must start first)
start_service "discovery-server" 8761 "$BASE_DIR/discovery-server"
sleep 10  # Give discovery server time to start

# 2. API Gateway
start_service "api-gateway" 8080 "$BASE_DIR/api-gateway"
sleep 5

# 3. Auth Service
start_service "auth-service" 8081 "$BASE_DIR/auth-service"
sleep 5

# 4. User Service
start_service "user-service" 8082 "$BASE_DIR/user-service"
sleep 5

# 5. Product Service
start_service "product-service" 8083 "$BASE_DIR/product-service"
sleep 5

echo ""
echo "⏳ Waiting for all services to be ready..."
sleep 20

echo ""
echo "🔍 Checking service health..."

services=(
    "discovery-server:8761"
    "api-gateway:8080"
    "auth-service:8081"
    "user-service:8082"
    "product-service:8083"
)

for service in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service"
    
    health_url="http://localhost:$port/actuator/health"
    if curl -s -f "$health_url" > /dev/null 2>&1; then
        echo "✅ $name is healthy"
    else
        echo "⚠️  $name may not be ready yet"
    fi
done

echo ""
echo "🎉 Microservices startup complete!"
echo ""
echo "🌐 Service URLs:"
echo "   Discovery Server: http://localhost:8761"
echo "   API Gateway:      http://localhost:8080"
echo "   Auth Service:     http://localhost:8081/actuator/health"
echo "   User Service:     http://localhost:8082/actuator/health"
echo "   Product Service:  http://localhost:8083/actuator/health"
echo ""
echo "📊 Monitoring URLs (if monitoring stack is running):"
echo "   Prometheus:       http://localhost:9090"
echo "   Grafana:          http://localhost:3000"
echo "   Zipkin:           http://localhost:9411"
echo ""
echo "📋 Service management:"
echo "   View logs:        tail -f logs/<service-name>.log"
echo "   Stop service:     kill \$(cat logs/<service-name>.pid)"
echo "   Stop all:         ./stop-services.sh"
