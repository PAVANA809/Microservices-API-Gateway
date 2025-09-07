#!/bin/bash

# Microservices Stop Script

echo "🛑 Stopping Microservices..."

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file="logs/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            echo "🔄 Stopping $service_name (PID: $pid)..."
            kill $pid
            
            # Wait up to 10 seconds for graceful shutdown
            for i in {1..10}; do
                if ! ps -p $pid > /dev/null 2>&1; then
                    echo "✅ $service_name stopped gracefully"
                    break
                fi
                sleep 1
            done
            
            # Force kill if still running
            if ps -p $pid > /dev/null 2>&1; then
                echo "⚡ Force stopping $service_name..."
                kill -9 $pid
            fi
        else
            echo "⚠️  $service_name (PID: $pid) is not running"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️  No PID file found for $service_name"
    fi
}

# Stop services in reverse order
services=(
    "product-service"
    "user-service"
    "auth-service"
    "api-gateway"
    "discovery-server"
)

for service in "${services[@]}"; do
    stop_service "$service"
    sleep 1
done

# Also try to kill any remaining Spring Boot processes
echo ""
echo "🔍 Checking for remaining Spring Boot processes..."

# Kill any remaining processes on known ports
ports=(8761 8080 8081 8082 8083)
for port in "${ports[@]}"; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo "🔄 Killing process on port $port (PID: $pid)..."
        kill -9 $pid 2>/dev/null || true
    fi
done

echo ""
echo "✅ All microservices stopped!"

# Clean up log files option
read -p "🗑️  Remove log files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f logs/*.log
    echo "🧹 Log files cleaned"
fi
