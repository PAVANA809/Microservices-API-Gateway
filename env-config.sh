#!/bin/bash

# Environment configuration for testing remote services
# Usage: source ./env-config.sh && ./test-apis.sh

# Set your server IP here
export API_HOST="192.168.56.104"
export DISCOVERY_HOST="192.168.56.104"

# Optional: Override default ports if needed
# export GATEWAY_PORT="8080"
# export AUTH_PORT="8081"
# export USER_PORT="8082"
# export PRODUCT_PORT="8083"
# export DISCOVERY_PORT="8761"

echo "🌐 Environment configured for remote testing:"
echo "   API Host: ${API_HOST}"
echo "   Discovery Host: ${DISCOVERY_HOST}"
echo ""
echo "🚀 Now run: ./test-apis.sh"
echo ""
echo "💡 Or run directly with environment variables:"
echo "   API_HOST=192.168.56.104 ./test-apis.sh"
