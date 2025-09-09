#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Service definitions
declare -A SERVICES
SERVICES["discovery-server"]="discovery-server"
SERVICES["api-gateway"]="api-gateway"
SERVICES["auth-service"]="auth-service"
SERVICES["user-service"]="user-service"
SERVICES["product-service"]="product-service"

# PID file directory
PID_DIR="$SCRIPT_DIR/pids"
mkdir -p "$PID_DIR"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if service is valid
is_valid_service() {
    local service=$1
    [[ -n "${SERVICES[$service]}" ]]
}

# Function to get service PID
get_service_pid() {
    local service=$1
    local pid_file="$PID_DIR/${service}.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        else
            # PID file exists but process is not running
            rm -f "$pid_file"
        fi
    fi
    return 1
}

# Function to check if service is running
is_service_running() {
    local service=$1
    get_service_pid "$service" >/dev/null
}

# Function to start a service
start_service() {
    local service=$1
    local service_dir="$SCRIPT_DIR/$service"
    local pid_file="$PID_DIR/${service}.pid"
    local log_file="$SCRIPT_DIR/logs/${service}.log"
    
    if is_service_running "$service"; then
        print_status "$YELLOW" "⚠️  Service '$service' is already running (PID: $(get_service_pid "$service"))"
        return 0
    fi
    
    if [[ ! -d "$service_dir" ]]; then
        print_status "$RED" "❌ Service directory '$service_dir' not found"
        return 1
    fi
    
    print_status "$BLUE" "🚀 Starting service '$service'..."
    
    # Create logs directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/logs"
    
    # Start the service in background
    cd "$service_dir"
    nohup mvn spring-boot:run > "$log_file" 2>&1 &
    local pid=$!
    
    # Save PID to file
    echo "$pid" > "$pid_file"
    
    # Wait a moment and check if service started successfully
    sleep 3
    if kill -0 "$pid" 2>/dev/null; then
        print_status "$GREEN" "✅ Service '$service' started successfully (PID: $pid)"
        print_status "$BLUE" "📄 Log file: $log_file"
        return 0
    else
        print_status "$RED" "❌ Failed to start service '$service'"
        rm -f "$pid_file"
        return 1
    fi
}

# Function to stop a service
stop_service() {
    local service=$1
    local pid_file="$PID_DIR/${service}.pid"
    
    if ! is_service_running "$service"; then
        print_status "$YELLOW" "⚠️  Service '$service' is not running"
        return 0
    fi
    
    local pid=$(get_service_pid "$service")
    print_status "$BLUE" "🛑 Stopping service '$service' (PID: $pid)..."
    
    # Try graceful shutdown first
    kill "$pid" 2>/dev/null
    
    # Wait up to 10 seconds for graceful shutdown
    local count=0
    while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
        sleep 1
        ((count++))
    done
    
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        print_status "$YELLOW" "⚠️  Graceful shutdown failed, force killing..."
        kill -9 "$pid" 2>/dev/null
        sleep 1
    fi
    
    # Clean up PID file
    rm -f "$pid_file"
    
    if ! kill -0 "$pid" 2>/dev/null; then
        print_status "$GREEN" "✅ Service '$service' stopped successfully"
        return 0
    else
        print_status "$RED" "❌ Failed to stop service '$service'"
        return 1
    fi
}

# Function to restart a service
restart_service() {
    local service=$1
    print_status "$BLUE" "🔄 Restarting service '$service'..."
    
    if is_service_running "$service"; then
        stop_service "$service"
        sleep 2
    fi
    
    start_service "$service"
}

# Function to show service status
show_status() {
    local service=$1
    
    if [[ "$service" == "all" ]]; then
        print_status "$BLUE" "📊 Service Status Overview:"
        echo "================================"
        for svc in "${!SERVICES[@]}"; do
            show_single_status "$svc"
        done
    else
        show_single_status "$service"
    fi
}

# Function to show single service status
show_single_status() {
    local service=$1
    local status_icon="❌"
    local status_text="STOPPED"
    local status_color="$RED"
    local pid_info=""
    
    if is_service_running "$service"; then
        status_icon="✅"
        status_text="RUNNING"
        status_color="$GREEN"
        pid_info=" (PID: $(get_service_pid "$service"))"
    fi
    
    printf "%-20s %s\n" "$service:" "$(echo -e "${status_color}${status_icon} ${status_text}${pid_info}${NC}")"
}

# Function to show service logs
show_logs() {
    local service=$1
    local log_file="$SCRIPT_DIR/logs/${service}.log"
    local lines=${2:-50}
    
    if [[ ! -f "$log_file" ]]; then
        print_status "$RED" "❌ Log file not found: $log_file"
        return 1
    fi
    
    print_status "$BLUE" "📄 Last $lines lines of $service logs:"
    echo "================================"
    tail -n "$lines" "$log_file"
}

# Function to follow service logs
follow_logs() {
    local service=$1
    local log_file="$SCRIPT_DIR/logs/${service}.log"
    
    if [[ ! -f "$log_file" ]]; then
        print_status "$RED" "❌ Log file not found: $log_file"
        return 1
    fi
    
    print_status "$BLUE" "📄 Following logs for $service (Press Ctrl+C to stop):"
    echo "================================"
    tail -f "$log_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <action> <service> [options]"
    echo ""
    echo "Actions:"
    echo "  start     Start a service"
    echo "  stop      Stop a service"
    echo "  restart   Restart a service"
    echo "  status    Show service status"
    echo "  logs      Show service logs"
    echo "  follow    Follow service logs in real-time"
    echo ""
    echo "Services:"
    for service in "${!SERVICES[@]}"; do
        echo "  $service"
    done
    echo "  all       (for status action only)"
    echo ""
    echo "Options:"
    echo "  --lines N    Number of log lines to show (default: 50)"
    echo ""
    echo "Examples:"
    echo "  $0 start discovery-server"
    echo "  $0 stop auth-service"
    echo "  $0 restart api-gateway"
    echo "  $0 status all"
    echo "  $0 logs user-service --lines 100"
    echo "  $0 follow product-service"
}

# Main function
main() {
    local action=$1
    local service=$2
    local lines=50
    
    # Parse additional arguments
    while [[ $# -gt 2 ]]; do
        case $3 in
            --lines)
                lines=$4
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Check if action is provided
    if [[ -z "$action" ]]; then
        show_usage
        exit 1
    fi
    
    # Check if service is provided (except for status all)
    if [[ -z "$service" ]] && [[ "$action" != "status" ]]; then
        print_status "$RED" "❌ Service name is required"
        show_usage
        exit 1
    fi
    
    # Validate service name (except for status all)
    if [[ -n "$service" ]] && [[ "$service" != "all" ]] && ! is_valid_service "$service"; then
        print_status "$RED" "❌ Invalid service name: '$service'"
        echo "Valid services: ${!SERVICES[*]}"
        exit 1
    fi
    
    # Execute action
    case $action in
        start)
            start_service "$service"
            ;;
        stop)
            stop_service "$service"
            ;;
        restart)
            restart_service "$service"
            ;;
        status)
            show_status "${service:-all}"
            ;;
        logs)
            show_logs "$service" "$lines"
            ;;
        follow)
            follow_logs "$service"
            ;;
        *)
            print_status "$RED" "❌ Invalid action: '$action'"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
